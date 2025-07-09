#!/usr/bin/env lua

local extract_content_length = function()
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

local extract_valid_payload = function(content_length)
	local payload = nil
	if content_length > 0 then
		payload = io.read(content_length)
	end
	if payload and string.match(payload, "^%d%d%d%d%-%d%d%-%d%d$") then
		return payload
	end
	return nil
end

local open_database = function(path)
	return require("luasql.sqlite3").sqlite3():connect(path) -- TODO: handle 3 sources of errors
end

local day_exists = function(db, id)
	local query = "SELECT * FROM day WHERE id = '" .. id .. "'"
	local result = db:execute(query)
	if result and result:fetch() then
		return true
	end
	return false
end

	-- TODO: 1/2
local extract_day = function(db, id)
	local query = "SELECT * FROM day WHERE id = '" .. id .. "'"
	local result = db:execute(query)
	if not result then
		return nil
	end

	local row = result:fetch({}, "a")
	while row do
--		for k, v in pairs(row) do
--			io.stderr:write(tostring(k) .. "," .. tostring(v) .. "\n")
--		end
		io.stderr:write("ID: " .. row.id .. ", notes: " .. tostring(row.notes) .. "\n")
		row = result:fetch(row, "a")
	end
	io.stderr:write("=====================================================================\n")

	local query = "SELECT * FROM rule_instance WHERE day_id = '" .. id .. "'"
	local result = db:execute(query)
	if not result then
		return nil
	end

	local row = result:fetch({}, "a")
	while row do
		for k, v in pairs(row) do
			io.stderr:write(tostring(k) .. "," .. tostring(v) .. "\n")
		end
--		io.stderr:write("ID: " .. row.id .. ", notes: " .. tostring(row.notes) .. "\n")
		row = result:fetch(row, "a")
	end

	return nil
end

local day_to_json = function(day)
	return "null"
	-- TODO 2/2
end

local make_day_json = function(db, id)
	return day_to_json(extract_day(db, id))
end

local respond = function(json)
	io.write("Status: 200 OK\r\n")
	io.write("Content-Type: application/json;charset=utf-8\r\n")
	io.write("Content-Length: " .. #json .. "\r\n\r\n")
	io.write(json)
end

local main = function()
	local payload = extract_valid_payload(extract_content_length())
	local database = open_database("cgi-bin/machine.db")
	if day_exists(database, payload) then
		respond(make_day_json(database, payload))
	else
		respond("null")
	end
end

main()
