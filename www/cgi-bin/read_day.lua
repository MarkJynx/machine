#!/usr/bin/env lua

local common = require("cgi-bin.common")
local cjson = require("cjson.safe")


local shallow_read = common.db_read_shallow(common.http_enforce_date_payload())
local response = cjson.encode(shallow_read) or "null"
common.http_respond(response)
