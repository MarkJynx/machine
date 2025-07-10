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
		element = result:fetch(element, "a")
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

-- TODO: generic function of table to JSON
local rule_instance_to_table = function(s, rule_instance)
	table.insert(s, "{'rule_name':")
	table.insert(s, "'" .. rule_instance.rule_name .. "',")
	table.insert(s, "'done':")
	table.insert(s, tostring(rule_instance.done))
	table.insert(s, "}")
end

common.day_to_json = function(day)
	if not day then
		return "null"
	end

	local s = {}
	table.insert(s, "{'id':")
	table.insert(s, "'" .. day.id .. "',")
	table.insert(s, "'notes':")
	if day.notes then
		table.insert(s, "'" .. day.notes .. "',")
	else
		table.insert(s, "null,")
	end
	table.insert(s, "'rule_instances':[")
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

return common
