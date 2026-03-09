#!/usr/bin/env lua

require("fun")()
local common = require("cgi-bin.common")
local cjson = require("cjson.safe")

local rule_applies = function(rule, date)
	local weekdays = common.get_rule_weekdays(rule)
	if not weekdays[common.date_weekday(date)] then
		return false
	end

	if rule.last_instance and common.date_diff(date, rule.last_instance.day_id) < rule.period then
		return false
	end

	return true
end

local main = function()
	local date = common.http_enforce_date_payload()
	local shallow = common.db_read_shallow(date)
	common.http_panic(shallow.day ~= nil)
	local rules = totable(filter(function(r) return rule_applies(r, date) end, shallow.rules))
	local day = { id = date, rule_instances = reduce(function(a, r) table.insert(a, {rule_name = r.name, done = 0}) return a end, {}, rules) }
	common.http_respond(cjson.encode(day) or "null")
end

main()
