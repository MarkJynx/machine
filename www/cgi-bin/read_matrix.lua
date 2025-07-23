#!/usr/bin/env lua

local common = require("cgi-bin.common")
local cjson = require("cjson.safe")


local extract_rule_done_lookup_table = function(rule)
	local lookup_table = {}
	for _, instance in ipairs(rule.rule_instances or {}) do
		if instance.done then
			lookup_table[rule.day_id] = true
		end
	end
	return lookup_table
end

local extract_rule_schedule_lookup_table = function(rule)
	local lookup_table = {}
	for _, schedule in ipairs(rule.rule_schedules or {}) do
		-- TODO: for each applicable weekday in schedule
	end
	return lookup_table
end

local extract_rules = function(database)
	local rules = common.collect_database(database, "SELECT * FROM rule ORDER BY order_priority ASC")
	for _, rule in ipairs(rules or {}) do
		rule.schedules = common.collect_database(database, "SELECT * FROM rule_schedule ORDER BY JULIANDAY(start_date)")
		rule.instances = common.collect_database(database, "SELECT * FROM rule_instance ORDER BY JULIANDAY(day_id)")
		rule.done_lt = extract_rule_done_lookup_table(rule)
		rule.schedule_lt = extract_rule_schedule_lookup_table(rule)
	end
	return rules
end

local extract_extreme_day = function(database, order)
	local q = "SELECT day_id FROM rule_instance ORDER BY JULIANDAY(day_id) %s LIMIT 1"
	local rule_instance = common.collect_single_record(database, string.format(q, order))
	if rule_instance then
		return rule_instance.day_id
	end
	return nil
end

local extract_day_lookup_table = function(database)
	local lookup_table = {}
	local days = common.collect_database(database, "SELECT * FROM day")
	for _, day in ipairs(days or {}) do
		lookup_table[day.id] = true
	end
	return lookup_table
end

local add_days = function(date, days)
	local t = os.time(common.date_string_to_date_table(date))
	local t2 = os.date("*t", t + days * 86400)
	return string.format("%04d-%02d-%02d", t2.year, t2.month, t2.day)
end

local rule_is_mandatory = function(date, schedule, done_lt)
	-- TODO: use done[rule][date] lookup table (check for up to schedule.period iterations)
	--1. 6. 2. 2. Check if mandatory (iterate over rule schedules & (last) instances).
	return false
end

local process_day_rule = function(row, date, rule, day_lt)
	if not day_lt[date] then
		table.insert(row, -1)
		return
	end

	local schedule = rule.schedule_lt[date]
	if not schedule then
		table.insert(row, -1)
		return
	end

	local done = rule.done_lt[date] and 1 or 0
	local mandatory = rule_is_mandatory(date, schedule, rule.done_lt)

	return done + (mandatory and 2 or 0)
end

local process_day = function(matrix, date, rules, day_lt)
	for _, rule in ipairs(rules or {}) do
		local row = {}
		process_day_rule(row, date, rule, day_lt)
		table.insert(matrix, row)
	end
end

local main = function()
	common.enforce_http_method("GET")
	local database = common.open_database("cgi-bin/machine.db")
	local rules = extract_rules(database)
	local day_lt = extract_day_lookup_table(database)
	local first_day = extract_extreme_day(database, "ASC")
	local last_day = extract_extreme_day(database, "DESC")
	local response = "false"
	local matrix = {}
	if first_day and last_day then
		local day_count = common.datediff(last_day, first_day)
		for i = 1, day_count + 1 do
			process_day(matrix, add_days(first_day, i - 1), rules, day_lt)
		end
	end
	--1. 7. Report results.
	--1. 8. Front-end work...
	common.respond(response)
	database:close()
end

main()
