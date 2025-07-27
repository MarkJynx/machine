#!/usr/bin/env lua

require("fun")()
local common = require("cgi-bin.common")
local cjson = require("cjson.safe")


local collect_rules = function(database, date)
	local r = common.collect_database(database, "SELECT * FROM rule ORDER BY order_priority ASC") or {}
	return totable(filter(function(x) return common.get_rule_schedule(database, r.name, date) ~= nil end, r))
end

local main = function()
	common.enforce_http_method("POST")
	local payload = common.extract_valid_date_payload(common.extract_content_length())
	local database = common.open_database("cgi-bin/machine.db")
	local rules = collect_rules(database, payload)
	local response = cjson.encode(rules) or "null"
	common.respond(response)
	database:close()
end

main()
