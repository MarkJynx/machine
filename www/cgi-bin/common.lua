require("fun")()
local common = {}

------------------------------------------------------------------
-- Date string utilities

local date_table = function(d)
	return { year = tonumber(d:sub(1, 4)), month = tonumber(d:sub(6, 7)), day = tonumber(d:sub(9, 10)) }
end

common.date_diff = function(d1, d2)
	return os.difftime(os.time(date_table(d1)), os.time(date_table(d2))) // 86400
end

common.date_weekday = function(d)
	return (os.date("%w", os.time(date_table(d))) + 7 - 1) % 7 + 1
end

common.date_add = function(date, days)
	local t = os.date("*t", os.time(date_table(date)) + days * 86400)
	return ("%04d-%02d-%02d"):format(t.year, t.month, t.day)
end

------------------------------------------------------------------
-- HTTP utilities

common.http_respond = function(json)
	if json then
		io.write("Status: 200 OK\r\n")
		io.write("Content-Type: application/json;charset=utf-8\r\n")
		io.write("Content-Length: " .. #json .. "\r\n\r\n")
		io.write(json)
	else
		io.write("Status: 500 Internal Server Error\r\n")
	end
	os.exit(0)
end

common.http_panic = function(condition)
	if (condition) then
		common.http_respond(nil)
	end
end

common.http_extract_content_length = function()
	-- We assume CONTENT_LENGTH is correct and we drain stdin of exactly that amount of bytes.
	-- We won't try draining (with DoS protection) stdin when there is more data than CONTENT_LENGTH.
	-- We won't try manually timeouting when there is less data than CONTENT_LENGTH.
	local content_length = os.getenv("CONTENT_LENGTH")
	if content_length then
		content_length = math.tointeger(content_length)
	end
	return content_length and content_length or 0
end

common.http_enforce_method = function(method)
	local request_method = os.getenv("REQUEST_METHOD")
	common.http_panic(request_method ~= method)
end

common.http_enforce_date_payload = function()
	common.http_enforce_method("POST")
	local content_length = common.http_extract_content_length()
	local payload = content_length > 0 and io.read(content_length) or nil
	common.http_panic(payload == nil or payload:match("^%d%d%d%d%-%d%d%-%d%d$") == nil)
	return payload
end

------------------------------------------------------------------
-- Stateless database operations

local DB_PATH = "cgi-bin/machine.db"
local DB_BACKUP_PATH = "cgi-bin/machine.sql"

local db_open = function(path) -- TODO: this needs refactorization: handle 3 sources of errors, close environment
	return require("luasql.sqlite3").sqlite3():connect(path)
end

local db_collect = function(db, q)
	local result = db:execute(q)
	if not result then
		return {}
	end

	local collection = {}
	local element = result:fetch({}, "a")
	while element do
		table.insert(collection, element)
		element = result:fetch({}, "a")
	end
	return collection
end

local db_collect_single = function(db, q)
	local results = db_collect(db, q)
	return #results == 1 and results[1] or nil
end

common.db_delete_day = function(date)
	local db = db_open(DB_PATH)
	local q = { "BEGIN TRANSACTION", nil, nil, "COMMIT" }
	q[2] = ("DELETE FROM rule_instance WHERE id = '%s'"):format(date)
	q[3] = ("DELETE FROM day WHERE id = '%s'"):format(date)
	local retval = all(function(q) return db:execute(q) ~= nil end, q)
	db:close()
	return retval
end

local db_get_last_rule_instance = function(db, rule_name, date)
	local q = "SELECT * FROM rule_instance WHERE rule_name = '%s' AND day_id <= '%s' AND done = 1 ORDER BY day_id DESC LIMIT 1"
	return db_collect_single(db, q:format(rule_name, date))
end

common.db_read_shallow = function(date)
	local db = db_open(DB_PATH)

	local rules = db_collect(db, "SELECT * FROM rule ORDER BY order_priority ASC")
	each(function(r) r.last_instance = db_get_last_rule_instance(db, r.name, date) end, rules)

	local day = db_collect_single(db, "SELECT * FROM day WHERE id = '" .. date .. "'")
	if day then
		local q = "SELECT * FROM rule_instance WHERE day_id = '" .. date .. "' ORDER BY order_priority ASC"
		day.rule_instances = db_collect(db, q)
	end

	db:close()

	return { rules = rules, day = day }
end

local db_read_deep_days = function(r, db)
	local days = db_collect(db, "SELECT * FROM day ORDER BY id ASC")
	r.day_count = 0
	if #days > 0 then
		r.day_first = days[1].id
		r.day_last = days[#days].id
		r.day_count = common.date_diff(r.day_last, r.day_first)
		r.day_lt = reduce(function(a, d) a[d.id] = true return a end, {}, days)
	end
end

local db_read_deep_rule_due_lt = function(rule, done_lt, r)
	local weekdays = common.get_rule_weekdays(rule)
	local not_done_streak = math.huge
	return reduce(function(lt, date)
		lt[date] = rule.period <= not_done_streak and weekdays[common.date_weekday(date)]
		not_done_streak = done_lt[date] and 1 or not_done_streak + 1
		if lt[date] and done_lt[date] == nil then
			lt[date] = nil
		end
		return lt
	end, {}, map(function(i) return common.date_add(r.day_first, i - 1) end, range(r.day_count)))
end

local db_read_deep_rule = function(r, db, rule)
	local s = ("SELECT * FROM rule_instance WHERE rule_name = '%s' ORDER BY day_id ASC"):format(db:escape(rule.name))
	rule.instances = db_collect(db, s)
	rule.done_lt = reduce(function(a, i) a[i.day_id] = (i.done == 1) return a end, {}, rule.instances)
	rule.due_lt = db_read_deep_rule_due_lt(rule, rule.done_lt, r)
end

local db_read_deep_rules = function(r, db)
	r.rules = db_collect(db, "SELECT * FROM rule ORDER BY order_priority ASC")
	each(function(rule) db_read_deep_rule(r, db, rule) end, r.rules)
end

common.db_read_deep = function()
	local r = {}
	local db = db_open(DB_PATH)
	db_read_deep_days(r, db)
	db_read_deep_rules(r, db)
	db:close()
	return r
end

local db_rule_instance_to_insert_query = function(i, db)
	local s1 = "INSERT OR ROLLBACK INTO rule_instance (rule_name, day_id, done, order_priority) VALUES "
	local s2 = string.format("('%s','%s',%d,%d)", db:escape(i.rule_name), i.day_id, i.done, i.order_priority)
	return s1 .. s2
end

common.db_insert_day = function(day)
	local db = db_open(DB_PATH)

	local s = { "PRAGMA foreign_keys = ON", "BEGIN TRANSACTION" }
	table.insert(s, string.format("DELETE FROM %s WHERE %s = '%s'", "rule_instance", "day_id", day.id))
	table.insert(s, string.format("DELETE FROM %s WHERE %s = '%s'", "day", "id", day.id))
	local notes = type(day.notes) == "string" and string.format("'%s'", db:escape(notes)) or "NULL"
	table.insert(s, string.format("INSERT OR ROLLBACK INTO day (id, notes) VALUES ('%s', %s)", day.id, notes))
	each(function(i) table.insert(s, db_rule_instance_to_insert_query(i, db)) end, day.rule_instances or {})
	table.insert(s, "COMMIT")
	local retval = all(function(q) return db:execute(q) ~= nil end, s)

	db:close()
	return retval
end

local db_backup_rule_instance = function(i, db, backup)
	local s = "INSERT INTO rule_instance (rule_name, day_id, done, order_priority) VALUES ("
	local rule_name = "'" .. i.rule_name .. "'," .. string.rep(" ", 26 - #i.rule_name) -- TODO: dynamic padding
	s = s .. string.format("%s'%s', %d, %2d);\n", rule_name, i.day_id, i.done, i.order_priority)
	backup:write(s)
end

local db_backup_day = function(date, db, backup)
	backup:write(("INSERT INTO day (id) VALUES ('%s');\n"):format(date))
	local q = "SELECT * FROM rule_instance WHERE day_id = '" .. date .. "' ORDER BY order_priority ASC"
	each(function(i) db_backup_rule_instance(i, db, backup) end, db_collect(db, q))
end

common.db_backup = function()
	local db = db_open(DB_PATH)
	local backup = io.open(DB_BACKUP_PATH, "wb")
	local days = db_collect(db, "SELECT * FROM day ORDER BY id ASC")
	each(function(day) db_backup_day(day.id, db, backup) end, days)
	backup:close()
	db:close()
end

------------------------------------------------------------------
-- Other

common.get_rule_weekdays = function(rule)
	return totable(map(function(i) return (rule.weekdays & (2 ^ (i - 1))) > 0 end, range(7)))
end

return common
