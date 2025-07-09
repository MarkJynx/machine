#!/usr/bin/env lua

local function main()
end

local function extract_content_length()
	-- We assume CONTENT_LENGTH is correct and we drain stdin of exactly that amount of bytes.
	-- We won't try draining (with DoS protection) stdin when there is more data than CONTENT_LENGTH.
	-- We won't try manually timeouting when there is less data than CONTENT_LENGTH.
	local content_length = os.getenv("CONTENT_LENGTH")
	if content_length ~= nil then
		content_length = tonumber(content_length, 10)
	end
	if content_length == nil then
		content_length = 0
	end
	return content_length
end

local function extract_valid_payload(content_length)
	local payload = nil
	if content_length > 0 then
		payload = io.read(content_length)
	end
	if payload ~= nil and string.match(payload, "^%d%d%d%d%-%d%d%-%d%d$") then
		return payload
	end
	return nil
end

local response = "null"

if payload ~= nil and string.match(payload, "^%d%d%d%d%-%d%d%-%d%d$") then
	local db = require("luasql.sqlite3").sqlite3():connect("cgi-bin/machine.db") -- TODO: check for errors
	local query = "SELECT * FROM day WHERE id = '" .. payload .. "'"
	local result = db:execute(query) -- TODO: check for errors
	if result:fetch({}, "a") then
		response = "{}"
		-- TODO: extract rule instaces
		-- TODO: extract day.note
		-- TODO: produce response
	end
end

io.write("Status: 200 OK\r\n")
io.write("Content-Type: application/json;charset=utf-8\r\n")
io.write("Content-Length: " .. #response .. "\r\n\r\n")
io.write(response)
