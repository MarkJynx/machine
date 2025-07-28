#!/usr/bin/env lua

require("fun")()
local common = require("cgi-bin.common")
local cjson = require("cjson.safe")


local main = function()
	local date = common.http_enforce_date_payload()
	local rules = common.db_read_shallow(date).rules -- TODO: check if db_read_shallow() does not return nil
	rules = totable(filter(function(r) return r.schedule ~= nil end, rules))
	local response = cjson.encode(rules) or "null"
	common.http_respond(response)
end

main()
