#!/usr/bin/env lua

local sqlite = require("luasql.sqlite3")

local content_length = os.getenv("CONTENT_LENGTH")
if content_length ~= nil then
	content_length = tonumber(content_length, 10)
end
if content_length == nil then
	content_length = 0
end

local payload = nil
if content_length > 0 then
	payload = io.read(content_length)
end

-- TODO: validate (match) payload
-- TODO: construct SQL query
-- TODO: execute SQL query
-- TODO: extract day
-- TODO: extract rule instaces
-- TODO: produce response

local response = "null"

io.write("Status: 200 OK\r\n")
io.write("Content-Type: application/json;charset=utf-8\r\n")
io.write("Content-Length: " .. #response .. "\r\n\r\n")
io.write(response)
