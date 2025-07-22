#!/usr/bin/env lua

local common = require("cgi-bin.common")
local cjson = require("cjson.safe")


local extract_rules = function(database)
	local rules = common.collect_database(database, "SELECT * FROM rule ORDER BY order_priority ASC")
	for _, rule in ipairs(rules or {}) do
		rule.schedules = common.collect_database(database, "SELECT * FROM rule_schedule ORDER BY JULIANDAY(start_date)")
		rule.instances = common.collect_database(database, "SELECT * FROM rule_instance ORDER BY JULIANDAY(day_id)")
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

local extract_days = function(database)
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

local process_day_rule = function(row, date, rule, days)
	if not days[date] then
		table.insert(row, -1)
		return
	end

	--1. 6. 2. 1. Check if applicable rule schedule exists. If not, fill with -1 and go to [2.6.2].
	--1. 6. 2. 2. Check if mandatory (iterate over rule schedules & (last) instances).
	--1. 6. 2. 3. Check if done (iterate over rule instances).
	--1. 6. 2. 4. Return anything from b00, b01, b10, b11
end

local process_day = function(matrix, date, rules, days)
	for _, rule in ipairs(rules or {}) do
		local row = {}
		process_day_rule(row, date, rule, days)
		table.insert(matrix, row)
	end
end

local main = function()
	common.enforce_http_method("GET")
	local database = common.open_database("cgi-bin/machine.db")
	local rules = extract_rules(database)
	local days = extract_days(database)
	local first_day = extract_extreme_day(database, "ASC")
	local last_day = extract_extreme_day(database, "DESC")
	local response = "false"
	local matrix = {}
	if first_day and last_day then
		local day_count = common.datediff(last_day, first_day)
		for i = 1, day_count + 1 do
			process_day(matrix, add_days(first_day, i - 1), rules, days)
		end
	end
	--1. 7. Report results.
	--1. 8. Front-end work...
	common.respond(response)
	database:close()
end

main()
