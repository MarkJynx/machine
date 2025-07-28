#!/usr/bin/env lua

require("fun")()
local common = require("cgi-bin.common")
local cjson = require("cjson.safe")


local rules = common.db_read_shallow(common.http_enforce_date_payload()).rules
rules = totable(filter(function(r) return r.schedule ~= nil end, rules))
local response = cjson.encode(rules) or "null"
common.http_respond(response)
