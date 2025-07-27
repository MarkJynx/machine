#!/usr/bin/env lua

require("fun")()
local common = require("cgi-bin.common")
local cjson = require("cjson.safe")


local main = function()
	local date = common.http_enforce_date_payload()
	local database = common.open_database("cgi-bin/machine.db")
	local rules = common.collect_database(database, "SELECT * FROM rule ORDER BY order_priority ASC") or {}
	rules = totable(filter(function(r) return common.get_rule_schedule(database, r.name, date) ~= nil end, rules))
	local response = cjson.encode(rules) or "null"
	common.http_respond(response)
	database:close()
end

main()
