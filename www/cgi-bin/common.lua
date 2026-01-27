require("fun")()
local common = {}


------------------------------------------------------------------
-- Date string utilities

local date_table = function(d)
	return { year = tonumber(string.sub(d, 1, 4)), month = tonumber(string.sub(d, 6, 7)), day = tonumber(string.sub(d, 9, 10)) }
end

common.date_diff = function(d1, d2)
	return os.difftime(os.time(date_table(d1)), os.time(date_table(d2))) // 86400
end

common.date_weekday = function(d)
	return (os.date("%w", os.time(date_table(d))) + 7 - 1) % 7 + 1
end

common.date_add = function(date, days)
	local t = os.time(date_table(date))
	local t2 = os.date("*t", t + days * 86400)
	return string.format("%04d-%02d-%02d", t2.year, t2.month, t2.day)
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
	if request_method ~= method then
		common.http_respond(nil)
	end
end

common.http_enforce_date_payload = function()
	common.http_enforce_method("POST")
	local content_length = common.http_extract_content_length()
	local payload = content_length > 0 and io.read(content_length) or nil
	if payload and string.match(payload, "^%d%d%d%d%-%d%d%-%d%d$") then
		return payload
	end
	common.http_respond(nil)
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

local db_get_rule_schedule = function(db, rule_name, date)
	local q = {}
	table.insert(q, string.format("SELECT * FROM rule_schedule WHERE rule_name = '%s' AND ", rule_name))
	table.insert(q, string.format("start_date <= '%s' AND ", date))
	table.insert(q, string.format("(end_date IS NULL OR end_date >= '%s')", date))
	return db_collect_single(db, table.concat(q)) -- TODO: this may fail, there can be multiple rules in same date span but with different weekdays
end

common.db_delete_day = function(date)
	local db = db_open(DB_PATH)
	local queries = { "BEGIN TRANSACTION", nil, nil, "COMMIT" }
	queries[2] = string.format("DELETE FROM %s WHERE %s = '%s'", "rule_instance", "day_id", date)
	queries[3] = string.format("DELETE FROM %s WHERE %s = '%s'", "day", "id", date)
	local retval = all(function(q) return db:execute(q) ~= nil end, queries)
	db:close()
	return retval
end

local db_get_last_rule_instance = function(db, name)
	local q = "SELECT * FROM rule_instance WHERE rule_name = '" .. db:escape(name) .. "' AND done = 1 ORDER BY day_id DESC LIMIT 1"
	return db_collect_single(db, q)
end

common.db_read_shallow = function(date)
	local db = db_open(DB_PATH)

	local rules = db_collect(db, "SELECT * FROM rule ORDER BY order_priority ASC")
	each(function(r) r.schedule = db_get_rule_schedule(db, r.name, date) end, rules)
	each(function(r) r.last_instance = db_get_last_rule_instance(db, r.name) end, rules)

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
	if #days > 0 then
		r.day_first = days[1].id
		r.day_last = days[#days].id
		r.day_lt = reduce(function(a, d) a[d.id] = true return a end, {}, days)
	end
end

local db_read_deep_rule_schedule_lt = function(lt, schedule, done_lt, r)
	if not r.day_first or not r.day_last then
		return lt
	end

	local schedule_weekdays = common.get_rule_schedule_weekdays(schedule)
	local start_date = max({schedule.start_date, r.day_first})
	local stop_date = schedule.stop_date and min({schedule.stop_day, r.day_last}) or r.day_last

	local not_done_streak = math.huge
	local day_count_before = min({schedule.period, common.date_diff(start_date, r.day_first)})
	for _, date in map(function(i) return common.date_add(start_date, -i) end, range(1, day_count_before, 1)) do
		if done_lt[date] then
			not_done_streak = common.date_diff(start_date, date)
			break
		end
	end

	local day_count = common.date_diff(stop_date, start_date) + 1
	for _, date in map(function(i) return common.date_add(start_date, i - 1) end, range(1, day_count, 1)) do
		lt[date] = schedule.period <= not_done_streak and schedule_weekdays[common.date_weekday(date)]
		not_done_streak = done_lt[date] and 1 or not_done_streak + 1
	end

	return lt
end

local db_read_deep_rule = function(r, db, rule)
	local s = "SELECT * FROM %s WHERE rule_name = '" .. db:escape(rule.name) .. "' %s ORDER BY %s ASC"
	rule.schedules = db_collect(db, string.format(s, "rule_schedule", "", "start_date"))
	rule.instances = db_collect(db, string.format(s, "rule_instance", "AND done = 1", "day_id"))
	rule.done_lt = reduce(function(a, i) a[i.day_id] = true return a end, {}, rule.instances)
	rule.schedule_lt = reduce(function(a, s) return db_read_deep_rule_schedule_lt(a, s, rule.done_lt, r) end, {}, rule.schedules)
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
	local s1 = "INSERT OR ROLLBACK INTO rule_instance (rule_name, rule_schedule_id, day_id, done, order_priority) VALUES "
	-- TODO: support NULL rule_schedule_id from WebUI
	local s2 = string.format("('%s',%d,'%s',%d,%d)", db:escape(i.rule_name), i.rule_schedule.id, i.day_id, i.done, i.order_priority)
	return s1 .. s2
end

common.db_insert_day = function(day)
	local db = db_open(DB_PATH)

	if any(function(i) i.rule_schedule = db_get_rule_schedule(db, i.rule_name, i.day_id) return i.rule_schedule == nil end, day.rule_instances) then
		db:close()
		return false
	end

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
	local s = "INSERT INTO rule_instance (rule_name, rule_schedule_id, day_id, done, order_priority) VALUES ("
	local rule_name = "'" .. i.rule_name .. "'," .. string.rep(" ", 26 - #i.rule_name) -- TODO: dynamic padding
	-- TODO: ternary operator function
	local rule_schedule_id = "NULL"
	if i.rule_schedule_id then
		rule_schedule_id = string.format("%4d", i.rule_schedule_id)
	end
	s = s .. string.format("%s%s, '%s', %d, %2d);\n", rule_name, rule_schedule_id, i.day_id, i.done, i.order_priority)
	backup:write(s)
end

local db_backup_day = function(date, db, backup)
	backup:write(string.format("INSERT INTO day (id) VALUES ('%s');\n", date)) -- TODO: support day.note
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

common.get_rule_schedule_weekdays = function(rule_schedule)
	return totable(map(function(i) return rule_schedule.weekdays & (2 ^ (i - 1)) end, range(7)))
end

return common
