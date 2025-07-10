local common = {}

-- TODO: validate anything you get from database

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

common.extract_valid_payload = function(content_length)
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
	local query = "SELECT * FROM day WHERE id = '" .. id .. "'"
	local result = db:execute(query)
	if result and result:fetch() then
		return true
	end
	return false
end

-- TODO: require cjson, jsonschema
local rule_instance_to_table = function(s, rule_instance)
	table.insert(s, string.format("{'rule_name':'%s','done':%d}", rule_instance.rule_name, rule_instance.done))
end

common.day_to_json = function(day)
	if not day then
		return "null"
	end

	local s = {}

	local notes = "null"
	if day.notes then
		notes = "'" .. day.notes .. "'"
	end

	table.insert(s, string.format("{'id':'%s','notes':%s,'rule_instance':[", day.id, notes))

	for i, rule_instance in ipairs(day.rule_instances) do
		rule_instance_to_table(s, rule_instance)
		if i < #day.rule_instances then
			table.insert(s, ",")
		end
	end

	table.insert(s, "]}")

	return table.concat(s)
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
