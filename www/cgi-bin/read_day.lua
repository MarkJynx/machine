#!/usr/bin/env lua5.4

require("os")

local content_length = os.getenv("CONTENT_LENGTH")
if content_length ~= nil then
	content_length = tonumber(content_length, 10)
end
if content_length == nil then
	content_length = 0
end

local payload = nil
if content_length > 0 then
	payload = io.read(content_length) -- TODO: expect read errors
end

io.write("Status: 200 OK\r\n")
io.write("Content-Type: application/json;charset=utf-8\r\n")
io.write("Content-Length: " .. #payload .. "\r\n\r\n")
io.write(payload)
