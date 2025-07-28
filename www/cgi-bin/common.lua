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
	return os.date("%w", os.time(date_table(d))) + 1
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
		return nil
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
	return (results and #results == 1) and results[1] or nil
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

	local rules = db_collect(db, "SELECT * FROM rule ORDER BY order_priority ASC") or {}
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
	if days and #days > 0 then
		r.day_first = days[1].id
		r.day_last = days[#days].id
		r.day_lt = reduce(function(a, d) a[d.id] = true return a end, {}, days)
	end
end

local extract_rule_schedule_lt = function(lt, done_lt, schedule, first_day, last_day) -- TODO: refactor, at least the name
	if not first_day or not last_day then
		return lt
	end

	local schedule_weekdays = common.get_rule_schedule_weekdays(schedule)
	local start_date = max({schedule.start_date, first_day})
	local stop_date = schedule.stop_date and min({schedule.stop_day, last_day}) or last_day

	local day_count = common.date_diff(stop_date, start_date) + 1
	local not_done_streak = math.huge
	for _, date in map(function(i) return common.date_add(start_date, i - 1) end, range(day_count)) do
		lt[date] = schedule.period <= not_done_streak and schedule_weekdays[common.date_weekday(date)]
		not_done_streak = done_lt[date] and 1 or not_done_streak + 1
	end

	return lt
end

local db_read_deep_rule = function(r, db, rule)
	local s = "SELECT * FROM %s WHERE rule_name = '" .. db:escape(rule.name) .. "' %s ORDER BY %s ASC"
	rule.schedules = db_collect(db, string.format(s, "rule_schedule", "", "start_date"))
	rule.instances = db_collect(db, string.format(s, "rule_instance", "AND done = 1", "day_id"))
	rule.done_lt = reduce(function(a, i) a[i.day_id] = true return a end, {}, rule.instances or {})
	rule.schedule_lt = reduce(function(a, s) return extract_rule_schedule_lt(a, rule.done_lt, s, r.day_first, r.day_last) end, {}, rule.schedules or {})
end

local db_read_deep_rules = function(r, db)
	r.rules = db_collect(db, "SELECT * FROM rule ORDER BY order_priority ASC")
	each(function(rule) db_read_deep_rule(r, db, rule) end, r.rules or {})
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
	table.insert(s, string.format("DELETE FROM %s WHERE %s = '%s'", "rule_instance", "day_id", date))
	table.insert(s, string.format("DELETE FROM %s WHERE %s = '%s'", "day", "id", date))
	local notes = type(day.notes) == "string" and string.format("'%s'", db:escape(notes)) or "NULL"
	table.insert(s, string.format("INSERT OR ROLLBACK INTO DAY (id, notes) VALUES ('%s', %s)", day.id, notes))
	each(function(i) table.insert(s, db_rule_instance_to_insert_query(i, db)) end, day.rule_instances or {})
	table.insert(s, "COMMIT")

	local retval = all(function(q) return db:execute(q) ~= nil end, s)
	db:close()
	return retval
end

local database_to_sql_day = function(day_id, database, sql_script) -- TODO: refactor, at least the name
	sql_script:write(string.format('INSERT INTO day (id) VALUES ("%s");\n', day_id))

	local q = "SELECT * FROM rule_instance WHERE day_id = '" .. day_id .. "' ORDER BY order_priority ASC"
	local rule_instances = db_collect(database, q)
	for _, r in ipairs(rule_instances or {}) do
		local rule_schedule = db_get_rule_schedule(database, r.rule_name, day_id) -- TODO: extremely inefficient bit in an extremely inefficient function
		local s = "INSERT INTO rule_instance (rule_name, rule_schedule_id, day_id, done, order_priority) VALUES ("
		-- TODO: dynamic padding
		local rule_name = '"' .. r.rule_name .. '",' .. string.rep(" ", 26 - #r.rule_name)
		s = s .. string.format('%s%2d, "%s", %d, %2d);\n', rule_name, rule_schedule.id, r.day_id, r.done, r.order_priority)
		sql_script:write(s)
	end
end

common.db_backup = function()
	local database = db_open(DB_PATH)
	local sql_script = io.open(DB_BACKUP_PATH, "wb")

	local days = db_collect(database, "SELECT * FROM day ORDER BY id ASC") or {}
	each(function(day) database_to_sql_day(day.id, database, sql_script) end, days)

	sql_script:close()
	database:close()
end

------------------------------------------------------------------
-- Other

common.get_rule_schedule_weekdays = function(rule_schedule)
	return totable(map(function(i) return rule_schedule.weekdays & (2 ^ (i - 1)) end, range(7)))
end

return common
