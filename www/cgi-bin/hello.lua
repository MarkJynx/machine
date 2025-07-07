#!/usr/bin/env lua5.1

--local payload = io.read("*all")
--payload = tostring(#payload)
payload = "[1,2,3]"
payload_length=7

--io.write("HTTP/1.0 200 OK\r\n")
io.write("Content-Type: application/json;charset=utf-8\r\n")
--io.write("Content-Length: " .. payload_length .. "\r\n\r\n")
print(payload)
