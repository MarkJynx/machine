#!/usr/bin/env lua

local common = require("cgi-bin.common")
local cjson = require("cjson.safe")


local collect_rules = function(database, date)
	local rules = common.collect_database(database, "SELECT * FROM rule ORDER BY order_priority ASC")
	for _, rule in ipairs(rules) do
		rule.schedule = common.get_rule_schedule(database, rule, date)
	end
	return rules
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
