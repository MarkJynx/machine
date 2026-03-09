#!/usr/bin/env lua

local common = require("cgi-bin.common")
local cjson = require("cjson.safe")

common.http_enforce_method("POST")
common.http_panic(common.http_extract_content_length() <= 0)
common.http_panic(not day or not day.id)
common.db_insert_day(day)
common.db_backup()
common.http_respond("true")
