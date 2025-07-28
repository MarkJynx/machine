#!/usr/bin/env lua

local common = require("cgi-bin.common")
local cjson = require("cjson.safe")


local day = common.db_read_shallow(common.http_enforce_date_payload()).day
local response = day and (cjson.encode(day) or "null") or "null"
common.http_respond(response)
