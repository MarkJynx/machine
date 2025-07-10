#!/usr/bin/env lua

local common = require("cgi-bin.common")

local get_rules = function(db)
	return rules = common.collect_database(db, "SELECT * FROM rule ORDER BY order_priority ASC")
end

local get_rule_schedule = function(db, rule, date)
	local q = {}
	table.insert(q, string.format("SELECT * FROM rule_schedule WHERE rule_name = '%s' AND ", rule.name))
	table.insert(q, string.format("JULIANDAY(start_date) >= JULIANDAY('%s') AND ", date))
	table.insert(q, string.format("(end_date IS NULL OR JULIANDAY(end_date) <= JULIANDAY('%s'))", date))
	local rule_schedule = common.collect_database(db, table.concat(q))
	if #rule_schedule ~= 1 then
		return nil
	end
	return rule_schedule[1]
end

local get_last_rule_instance(db, rule)
	-- TODO
	return nil
end

local rule_applies = function(rule_schedule, last_rule_instance, date)
	-- TODO 1: check weekdays
	-- TODO 2: compare difference between date and last_rule_instance.day_id and rule_schedule.period
	return nil
end

local main = function()
	local payload = common.extract_valid_payload(common.extract_content_length())
	local database = common.open_database("cgi-bin/machine.db")
	if common.day_exists(database, payload) then
		common.respond("null")
	else
		local day = { id = payload, rule_instances = {} }
		local rules = get_rules(database)
		for _, rule in ipairs(rules) do
			local rule_schedule = get_rule_schedule(database, rule, payload)
			local last_rule_instance = get_last_rule_instance(database, rule)
			if rule_applies(rule_schedule, last_rule_instance, payload) then
				table.insert(day.rule_instances, { rule_name = rule.name, done = 0 })
			end
		end
		common.respond(common.day_to_json(day))
	end
end

main()
