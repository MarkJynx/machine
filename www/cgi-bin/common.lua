local common = {}


common.enforce_http_method = function(method)
	local request_method = os.getenv("REQUEST_METHOD")
	if request_method ~= method then
		os.exit(0)
	end
end


common.extract_content_length = function()
	-- We assume CONTENT_LENGTH is correct and we drain stdin of exactly that amount of bytes.
	-- We won't try draining (with DoS protection) stdin when there is more data than CONTENT_LENGTH.
	-- We won't try manually timeouting when there is less data than CONTENT_LENGTH.
	local content_length = os.getenv("CONTENT_LENGTH")
	if content_length then
		content_length = tonumber(content_length, 10)
	end
	if content_length == nil then
		content_length = 0
	end
	return content_length
end

common.extract_valid_date_payload = function(content_length)
	-- TODO: convert to JSON
	local payload = nil
	if content_length > 0 then
		payload = io.read(content_length)
	end
	if payload and string.match(payload, "^%d%d%d%d%-%d%d%-%d%d$") then
		return payload
	end
	return nil
end

common.open_database = function(path)
	return require("luasql.sqlite3").sqlite3():connect(path) -- TODO: handle 3 sources of errors, close environment
end

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

common.collect_single_record = function(db, q)
	local results = common.collect_database(db, q)
	if #results == 1 then
		return results[1]
	end
	return nil
end

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

common.get_rule_schedule_weekdays = function(rule_schedule)
	local rule_schedule_weekdays = { }
	for i = 1, 7 do
		rule_schedule_weekdays[i] = rule_schedule.weekdays & (2 ^ (i - 1))
	end
	return rule_schedule_weekdays
end

common.execute_many_database_queries = function(db, queries)
	local success = true
	for _, query in ipairs(queries) do
		local result = db:execute(query)
		if not result then
			success = false
			break
		end
	end
	return success
end

common.day_exists = function(db, id)
	-- TODO: validate anything you get from database
	local query = "SELECT * FROM day WHERE id = '" .. id .. "'"
	local result = db:execute(query)
	if result and result:fetch() then
		return true
	end
	return false
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
	local days = common.collect_database(database, "SELECT * FROM day ORDER BY JULIANDAY(id) ASC")
	for index, day in ipairs(days or {}) do
		database_to_sql_day(day.id, database, sql_script)
		if index ~= #days then
			sql_script:write("\n")
		end
	end
	sql_script:close()
end

common.validate_day = function(day)
	-- TODO: use JSON schema and Teal
	if type(day) ~= "table" then
		return false
	end

	if type(day.id) ~= "string" or not string.match(day.id, "^%d%d%d%d%-%d%d%-%d%d$") then
		return false
	end

	if day.rule_instances == nil then
		return true
	end

	if type(day.rule_instances) ~= "table" then
		return false
	end

	for _, rule_instance in pairs(day.rule_instances) do
		-- TODO: validate rule_name against available rule names
		if type(rule_instance.rule_name) ~= "string" then
			return false
		end
		if rule_instance.day_id ~= day.id then
			return false
		end
		if rule_instance.done ~= 0 and rule_instance.done ~= 1 then
			return false
		end
		if type(rule_instance.order_priority) ~= "number" or rule_instance.order_priority <= 0 then
			-- TODO: validate it is an integer
			return false
		end
	end

	return true
end

common.respond = function(json)
	io.write("Status: 200 OK\r\n")
	io.write("Content-Type: application/json;charset=utf-8\r\n")
	io.write("Content-Length: " .. #json .. "\r\n\r\n")
	io.write(json)
end

common.date_string_to_date_table = function(s)
	return {
		year = tonumber(string.sub(s, 1, 4)),
		month = tonumber(string.sub(s, 6, 7)),
		day = tonumber(string.sub(s, 9, 10))
	}
end

common.datediff = function(d1, d2)
	local t1 = os.time(common.date_string_to_date_table(d1))
	local t2 = os.time(common.date_string_to_date_table(d2))
	local dt = os.difftime(t1, t2)
	return dt // 86400
end

common.dateweekday = function(d)
	return os.date("%w", os.time(common.date_string_to_date_table(d))) + 1
end

return common
