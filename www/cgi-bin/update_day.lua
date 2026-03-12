#!/usr/bin/env lua

local c = require("cgi-bin.common")
local cjson = require("cjson.safe")

c.http_enforce_method("POST")
local content_length = c.http_extract_content_length()
c.http_panic(content_length <= 0)
local day = cjson.decode(io.read(content_length))
c.http_panic(not day or not day.id)
c.db_insert_day(day)
c.db_backup()
c.http_respond("true")
