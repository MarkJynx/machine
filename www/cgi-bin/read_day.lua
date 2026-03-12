#!/usr/bin/env lua

local c = require("cgi-bin.common")
local cjson = require("cjson.safe")

local shallow_read = c.db_read_shallow(c.http_enforce_date_payload())
c.http_respond(cjson.encode(shallow_read) or "null")
