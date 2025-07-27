#!/usr/bin/env lua

require("fun")()
local common = require("cgi-bin.common")
local cjson = require("cjson.safe")


local get_last_rule_instance = function(db, rule)
	-- TODO: validate anything you get from database
	local q = "SELECT * FROM rule_instance WHERE rule_name = '" .. rule.name .. "' AND done = 1 ORDER BY JULIANDAY(day_id) DESC LIMIT 1"
	return common.collect_single_record(db, q)
end

local rule_applies = function(rule_schedule, last_rule_instance, date)
	if not rule_schedule then
		return false
	end

	local date_weekday = common.dateweekday(date)
	local rule_schedule_weekdays = common.get_rule_schedule_weekdays(rule_schedule)
	if not rule_schedule_weekdays[date_weekday] then
		return false
	end

	if not last_rule_instance then
		return true
	end

	if common.datediff(date, last_rule_instance.day_id) < rule_schedule.period then
		return false
	end

	return true
end

local main = function()
	common.enforce_http_method("POST")
	local date = common.extract_valid_date_payload(common.extract_content_length())
	local db = common.open_database("cgi-bin/machine.db")
	local response = "null"
	if date and not common.day_exists(db, date) then
		local rules = common.collect_database(db, "SELECT * FROM rule ORDER BY order_priority ASC") or {}
		rules = totable(filter(function(r) return rule_applies(common.get_rule_schedule(db, r.name, date), get_last_rule_instance(db, r), date) end, rules))

		local day = { id = date, rule_instances = {} }
	    each(function(r) table.insert(day.rule_instances, { rule_name = r.name, done = 0 }) end, rules)
		response = cjson.encode(day) or "null"
	end
	common.respond(response)
	db:close()
end

main()
