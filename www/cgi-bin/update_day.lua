#!/usr/bin/env lua

local common = require("cgi-bin.common")
local cjson = require("cjson.safe")


common.http_enforce_method("POST")
local content_length = common.http_extract_content_length()
if content_length <= 0 then
	common.http_respond(nil)
end
local day = cjson.decode(io.read(content_length))
if not day or not day.id then
	common.http_respond(nil)
end
common.db_insert_day(day)
common.db_backup()
common.http_respond("true")
