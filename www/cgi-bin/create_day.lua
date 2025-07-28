#!/usr/bin/env lua

require("fun")()
local common = require("cgi-bin.common")
local cjson = require("cjson.safe")


local rule_applies = function(rule_schedule, last_rule_instance, date)
	if not rule_schedule then
		return false
	end

	local date_weekday = common.date_weekday(date)
	local rule_schedule_weekdays = common.get_rule_schedule_weekdays(rule_schedule)
	if not rule_schedule_weekdays[date_weekday] then
		return false
	end

	if last_rule_instance and common.date_diff(date, last_rule_instance.day_id) < rule_schedule.period then
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

	local rules = totable(filter(function(r) return rule_applies(r.schedule, r.last_instance, date) end, shallow.rules))

	local day = { id = date, rule_instances = {} }
	each(function(r) table.insert(day.rule_instances, { rule_name = r.name, done = 0 }) end, rules)
	common.http_respond(cjson.encode(day) or "null")
end

main()
