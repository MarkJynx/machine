local common = {}


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

common.day_exists = function(db, id)
	-- TODO: validate anything you get from database
	local query = "SELECT * FROM day WHERE id = '" .. id .. "'"
	local result = db:execute(query)
	if result and result:fetch() then
		return true
	end
	return false
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

return common
