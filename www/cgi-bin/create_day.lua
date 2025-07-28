#!/usr/bin/env lua

require("fun")()
local common = require("cgi-bin.common")
local cjson = require("cjson.safe")


local rule_applies = function(rule, date)
	if not rule.schedule then
		return false
	end

	local schedule_weekdays = common.get_rule_schedule_weekdays(rule.schedule)
	if not schedule_weekdays[common.date_weekday(date)] then
		return false
	end

	if rule.last_instance and common.date_diff(date, rule.last_instance.day_id) < rule.schedule.period then
		return false
	end

	return true
end

local main = function()
	local date = common.http_enforce_date_payload()
	local shallow = common.db_read_shallow(date)
	if shallow.day then
		common.http_response(nil)
	end

	local rules = totable(filter(function(r) return rule_applies(r, date) end, shallow.rules))
	local day = { id = date, rule_instances = {} }
	each(function(r) table.insert(day.rule_instances, { rule_name = r.name, done = 0 }) end, rules)

	common.http_respond(cjson.encode(day) or "null")
end

main()
