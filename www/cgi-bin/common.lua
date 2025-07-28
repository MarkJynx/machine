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

-- TODO: delete / convert to local function
local open_database = function(path)
	return require("luasql.sqlite3").sqlite3():connect(path) -- TODO: handle 3 sources of errors, close environment
end

-- TODO: delete / convert to local function
local collect_database = function(db, q)
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

local execute_many_database_queries = function(db, queries)
	return all(function(q) return db:execute(q) ~= nil end, queries)
end

-- TODO: delete / convert to local function
local collect_single_record = function(db, q)
	local results = collect_database(db, q)
	return (results and #results == 1) and results[1] or nil
end

-- TODO: delete / convert to local function
local get_rule_schedule = function(db, rule_name, date) -- TODO: make common functions bullet-proof, check everything
	if not date then
		return nil
	end

	local q = {}
	-- TODO: validate anything you get from database
	table.insert(q, string.format("SELECT * FROM rule_schedule WHERE rule_name = '%s' AND ", rule_name))
	table.insert(q, string.format("JULIANDAY(start_date) <= JULIANDAY('%s') AND ", date))
	table.insert(q, string.format("(end_date IS NULL OR JULIANDAY(end_date) >= JULIANDAY('%s'))", date))
	q = table.concat(q)

	return collect_single_record(db, q)
end

common.db_delete_day = function(date)
	local database = open_database(DB_PATH)

	local q = {}
	table.insert(q, "BEGIN TRANSACTION")
	table.insert(q, "DELETE FROM rule_instance WHERE day_id = '" .. date .. "'")
	table.insert(q, "DELETE FROM day WHERE id = '" .. date .. "'")
	table.insert(q, "COMMIT")
	local retval = execute_many_database_queries(database, q)

	database:close()

	return retval
end

local get_last_rule_instance = function(db, name)
	local q = "SELECT * FROM rule_instance WHERE rule_name = '" .. db:escape(name) .. "' AND done = 1 ORDER BY JULIANDAY(day_id) DESC LIMIT 1"
	return collect_single_record(db, q)
end

common.db_read_shallow = function(date)
	local db = open_database(DB_PATH)

	local rules = collect_database(db, "SELECT * FROM rule ORDER BY order_priority ASC") or {}
	each(function(r) r.schedule = get_rule_schedule(db, r.name, date) end, rules)
	each(function(r) r.last_instance = get_last_rule_instance(db, r.name) end, rules)

	local day = collect_single_record(db, "SELECT * FROM day WHERE id = '" .. date .. "'")
	if day then
		local q = "SELECT * FROM rule_instance WHERE day_id = '" .. date .. "' ORDER BY order_priority ASC"
		day.rule_instances = collect_database(db, q)
	end

	db:close()

	return { rules = rules, day = day }
end

local db_read_deep_days = function(r, db)
	local days = collect_database(db, "SELECT * FROM day ORDER BY id ASC")
	if not days then
		return
	end
	r.day_first = days[1].id
	r.day_last = days[#days].id
	r.day_lt = reduce(function(a, d) a[d.id] = true return a end, {}, days)
end

local extract_rule_done_lt = function(instances)
	return reduce(function(a, i) if i.done then a[i.day_id] = true end return a end, {}, instances)
end

local extract_rule_schedule_lt = function(lt, done_lt, schedule, first_day, last_day)
	local rule_schedule_weekdays = get_rule_schedule_weekdays(schedule)
	local start_date = max({schedule.start_date, first_day})
	local stop_date = schedule.stop_date and min({schedule.stop_day, last_day}) or last_day

	local day_count = common.date_diff(stop_date, start_date) + 1
	local not_done_streak = math.huge
	for i = 1, day_count do
		local current_date = common.date_add(start_date, i - 1)
		local date_weekday = common.date_weekday(current_date)
		lt[current_date] = schedule.period <= not_done_streak and rule_schedule_weekdays[date_weekday]
		not_done_streak = done_lt[current_date] and 1 or not_done_streak + 1
	end

	return lt
end

local extract_rule_schedule_lt_all = function(first_day, last_day, done_lt, schedules)
	return reduce(function(a, s) return extract_rule_schedule_lt(a, done_lt, s, first_day, last_day) end, {}, schedules)
end

local db_read_deep_rule = function(r, db, rule)
	local selector = "WHERE rule_name = '" .. db:escape(rule.name) .. "'"
	local q1 = "SELECT * FROM rule_schedule " .. selector .. " ORDER BY JULIANDAY(start_date) ASC"
	local q2 = "SELECT * FROM rule_instance " .. selector .. " AND done = 1 ORDER BY JULIANDAY(day_id) ASC"
	rule.schedules = collect_database(db, q1)
	rule.instances = collect_database(db, q2)
	rule.done_lt = extract_rule_done_lt(rule.instances or {})
	rule.schedule_lt = extract_rule_schedule_lt_all(r.day_first, r.day_last, rule.done_lt, rule.schedules or {})
end

local db_read_deep_rules = function(r, db)
	r.rules = collect_database(db, "SELECT * FROM rule ORDER BY order_priority ASC")
	each(function(rule) db_read_deep_rule(r, db, rule) end, r.rules or {})
end

common.db_read_deep = function()
	local r = {}
	local db = open_database(DB_PATH)

	db_read_deep_days(r, db)
	db_read_deep_rules(r, db)

	db:close()
	return r
end

local assign_rule_schedules = function(day, database)
	return all(function(i) i.rule_schedule = get_rule_schedule(database, i.rule_name, i.day_id) return i.rule_schedule ~= nil end, day.rule_instances)
end

local rule_instance_to_insert_query = function(rule_instance, day_id, database)
	local q = {}
	table.insert(q, "INSERT OR ROLLBACK INTO rule_instance")
	table.insert(q, "(rule_name, rule_schedule_id, day_id, done, order_priority) VALUES (")
	table.insert(q, "'" .. database:escape(rule_instance.rule_name) .. "',")
	table.insert(q, tostring(rule_instance.rule_schedule.id))
	table.insert(q, string.format(",'%s',%d,%d)", day_id, rule_instance.done, rule_instance.order_priority))
	return table.concat(q)
end

common.db_insert_day = function(day)
	local retval = false
	local database = open_database(DB_PATH)

	if not assign_rule_schedules(day, database) then
		database:close()
		return false
	end

	local s = {}
	table.insert(s, "PRAGMA foreign_keys = ON")
	table.insert(s, "BEGIN TRANSACTION")
	table.insert(s, "DELETE FROM rule_instance WHERE day_id = '" .. day.id .. "'")
	table.insert(s, "DELETE FROM day WHERE id = '" .. day.id .. "'")
	local notes = "NULL"
	if type(day.notes) == "string" then
		notes = "'" .. database:escape(day.notes) .. "'"
	end
	table.insert(s, "INSERT OR ROLLBACK INTO day ( id, notes) VALUES ( '" .. day.id .. "', " .. notes .. ')')
	each(function(i) table.insert(s, rule_instance_to_insert_query(i, day.id, database)) end, day.rule_instances or {})
	table.insert(s, "COMMIT")

	if execute_many_database_queries(database, s) then
		retval = true
	end

	database:close()
	return retval
end

local database_to_sql_day = function(day_id, database, sql_script)
	sql_script:write(string.format('INSERT INTO day (id) VALUES ("%s");\n', day_id))

	local q = "SELECT * FROM rule_instance WHERE day_id = '" .. day_id .. "' ORDER BY order_priority ASC"
	local rule_instances = collect_database(database, q)
	for _, r in ipairs(rule_instances or {}) do
		local rule_schedule = get_rule_schedule(database, r.rule_name, day_id) -- TODO: extremely inefficient bit in an extremely inefficient function
		local s = "INSERT INTO rule_instance (rule_name, rule_schedule_id, day_id, done, order_priority) VALUES ("
		-- TODO: dynamic padding
		local rule_name = '"' .. r.rule_name .. '",' .. string.rep(" ", 26 - #r.rule_name)
		s = s .. string.format('%s%2d, "%s", %d, %2d);\n', rule_name, rule_schedule.id, r.day_id, r.done, r.order_priority)
		sql_script:write(s)
	end
end

common.db_backup = function()
	local database = open_database(DB_PATH)
	local sql_script = io.open(DB_BACKUP_PATH, "wb")

	local days = collect_database(database, "SELECT * FROM day ORDER BY JULIANDAY(id) ASC") or {}
	each(function(day) database_to_sql_day(day.id, database, DB_BACKUP_PATH) end, days)

	sql_script:close()
	database:close()
end

------------------------------------------------------------------
-- Other

get_rule_schedule_weekdays = function(rule_schedule)
	return totable(map(function(i) return rule_schedule.weekdays & (2 ^ (i - 1)) end, range(7)))
end

return common
