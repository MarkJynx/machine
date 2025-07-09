#!/usr/bin/env lua

local DB_PATH = "my.db"

local sqlite = require("luasql.sqlite3")
local sqlite_env = sqlite.sqlite3() -- TODO: check for errors
assert(sqlite_env)
local sqlite_db = sqlite_env:connect(DB_PATH)
assert(sqlite_db)

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

local response = "null"

os.execute("pwd 1>&2")
if payload ~= nil and string.match(payload, "^%d%d%d%d-%d%d-%d%d$") then
--	local query = "SELECT * FROM day WHERE id = '" .. payload .. "'"
	local query = "SELECT id FROM day"
	local result = sqlite_db:execute(query)
	assert(result)
	local row = result:fetch({}, "a")
	if row then
		response = "{}"
		-- TODO: extract day
		-- TODO: extract rule instaces
		-- TODO: produce response
	end
end

io.write("Status: 200 OK\r\n")
io.write("Content-Type: application/json;charset=utf-8\r\n")
io.write("Content-Length: " .. #response .. "\r\n\r\n")
io.write(response)
