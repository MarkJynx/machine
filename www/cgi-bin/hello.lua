#!/usr/bin/env lua5.1

--local payload = io.read("*all")
local payload = "hello POST"

print("Status: 200 OK")
print("Content-length: " .. tostring(#payload))
print("Content-Type: application/json;charset=utf-8\n")
print(payload)
