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

-- TODO: delete / convert to local function
common.open_database = function(path)
	return require("luasql.sqlite3").sqlite3():connect(path) -- TODO: handle 3 sources of errors, close environment
end

-- TODO: delete / convert to local function
common.collect_database = function(db, q)
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

-- TODO: delete / convert to local function
common.collect_single_record = function(db, q)
	local results = common.collect_database(db, q)
	return #results == 1 and results[1] or nil
end

-- TODO: delete / convert to local function
common.get_rule_schedule = function(db, rule_name, date) -- TODO: make common functions bullet-proof, check everything
	if not date then
		return nil
	end

	local q = {}
	-- TODO: validate anything you get from database
	table.insert(q, string.format("SELECT * FROM rule_schedule WHERE rule_name = '%s' AND ", rule_name))
	table.insert(q, string.format("JULIANDAY(start_date) <= JULIANDAY('%s') AND ", date))
	table.insert(q, string.format("(end_date IS NULL OR JULIANDAY(end_date) >= JULIANDAY('%s'))", date))
	q = table.concat(q)

	return common.collect_single_record(db, q)
end

-- TODO: delete / convert to local function
common.day_exists = function(db, id)
	-- TODO: validate anything you get from database
	return common.collect_single_record(db, "SELECT * FROM day WHERE id = '" .. id .. "'") ~= nil
end

common.db_delete_day = function(day)
	local database = common.open_database("cgi-bin/machine.db")

	local q = {}
	table.insert(q, "BEGIN TRANSACTION")
	table.insert(q, "DELETE FROM rule_instance WHERE day_id = '" .. day .. "'")
	table.insert(q, "DELETE FROM day WHERE id = '" .. day .. "'")
	table.insert(q, "COMMIT")
	local retval = common.execute_many_database_queries(database, q)

	database:close()

	return retval
end

common.db_read_shallow = function(day)
	local db = common.open_database("cgi-bin/machine.db")

	local rules = common.collect_database(db, "SELECT * FROM rule ORDER BY order_priority ASC") or {}
	each(function(r) r.schedule = common.get_rule_schedule(db, r.name, day) end, rules)

	db:close()

	return rules
end

------------------------------------------------------------------
-- Other

-- TODO: separate backup functions

common.get_rule_schedule_weekdays = function(rule_schedule)
	return totable(map(function(i) return rule_schedule.weekdays & (2 ^ (i - 1)) end, range(7)))
end

common.execute_many_database_queries = function(db, queries)
	return all(function(q) return db:execute(q) ~= nil end, queries)
end

local database_to_sql_day = function(day_id, database, sql_script)
	sql_script:write(string.format('INSERT INTO day (id) VALUES ("%s");\n', day_id))

	local q = "SELECT * FROM rule_instance WHERE day_id = '" .. day_id .. "' ORDER BY order_priority ASC"
	local rule_instances = common.collect_database(database, q)
	for _, r in ipairs(rule_instances or {}) do
		local rule_schedule = common.get_rule_schedule(database, r.rule_name, day_id) -- TODO: extremely inefficient bit in an extremely inefficient function
		local s = "INSERT INTO rule_instance (rule_name, rule_schedule_id, day_id, done, order_priority) VALUES ("
		-- TODO: dynamic padding
		local rule_name = '"' .. r.rule_name .. '",' .. string.rep(" ", 26 - #r.rule_name)
		s = s .. string.format('%s%2d, "%s", %d, %2d);\n', rule_name, rule_schedule.id, r.day_id, r.done, r.order_priority)
		sql_script:write(s)
	end
end

common.database_to_sql = function (database, sql_path)
	local sql_script = io.open(sql_path, "wb")
	local days = common.collect_database(database, "SELECT * FROM day ORDER BY JULIANDAY(id) ASC") or {}
	each(function(day) database_to_sql_day(day.id, database, sql_script) end, days)
	sql_script:close()
end

return common
