#!/usr/bin/env lua

require("fun")()
local common = require("cgi-bin.common")
local cjson = require("cjson.safe")


local add_days = function(date, days)
	local t = os.time(common.date_string_to_date_table(date))
	local t2 = os.date("*t", t + days * 86400)
	return string.format("%04d-%02d-%02d", t2.year, t2.month, t2.day)
end

local extract_rule_done_lt = function(rule)
	return reduce(function(a, r) if r.done then a[r.day_id] = true end return a end, {}, rule.instances or {})
end

local extract_rule_schedule_lt_schedule = function(lt, done_lt, schedule, first_day, last_day)
	local rule_schedule_weekdays = common.get_rule_schedule_weekdays(schedule)

	local start_date = first_day
	if schedule.start_date and common.datediff(schedule.start_date, first_day) > 0 then
		start_date = schedule.start_date
	end

	local stop_date = last_day
	if schedule.stop_date and common.datediff(schedule.stop_date, last_day) < 0 then
		stop_date = schedule.stop_date
	end

	local day_count = common.datediff(stop_date, start_date) + 1
	local not_done_streak = 999 -- TODO: use token value
	for i = 1, day_count do
		local current_date = add_days(start_date, i - 1)
		lt[current_date] = false

		local date_weekday = common.dateweekday(current_date)
		if schedule.period <= not_done_streak and rule_schedule_weekdays[date_weekday] then
			lt[current_date] = true
		end

		not_done_streak = not_done_streak + 1
		if done_lt[current_date] then
			not_done_streak = 1
		end
	end

	return lt
end

local extract_rule_schedule_lt = function(rule, first_day, last_day)
	return reduce(function(a, s) return extract_rule_schedule_lt_schedule(a, rule.done_lt, s, first_day, last_day) end, {}, rule.schedules or {})
end

local extract_rules = function(database, first_day, last_day)
	local rules = common.collect_database(database, "SELECT * FROM rule ORDER BY order_priority ASC")
	for _, rule in ipairs(rules or {}) do
		local selector = "WHERE rule_name = '" .. database:escape(rule.name) .. "'"
		local q1 = "SELECT * FROM rule_schedule " .. selector .. " ORDER BY JULIANDAY(start_date) ASC"
		local q2 = "SELECT * FROM rule_instance " .. selector .. " AND done = 1 ORDER BY JULIANDAY(day_id) ASC"
		rule.schedules = common.collect_database(database, q1)
		rule.instances = common.collect_database(database, q2)
		rule.done_lt = extract_rule_done_lt(rule)
		rule.schedule_lt = extract_rule_schedule_lt(rule, first_day, last_day)
	end
	return rules
end

local extract_extreme_day = function(database, order)
	local q = "SELECT day_id FROM rule_instance ORDER BY JULIANDAY(day_id) %s LIMIT 1"
	local rule_instance = common.collect_single_record(database, string.format(q, order))
	return rule_instance and rule_instance.day_id or nil
end

local extract_day_lt = function(database)
	local days = common.collect_database(database, "SELECT * FROM day") or {}
	return reduce(function(a, d) a[d.id] = true return a end, {}, days)
end

local process_day_rule = function(row, date, rule, day_lt)
	if not day_lt[date] or rule.schedule_lt[date] == nil then
		table.insert(row, -1)
	else
		local done = rule.done_lt[date] and 1 or 0
		local mandatory = rule.schedule_lt[date] and 2 or 0
		table.insert(row, done + mandatory)
	end
	return row
end

local process_day = function(matrix, date, rules, day_lt)
	local row = reduce(function(a, r) return process_day_rule(a, date, r, day_lt) end, {}, rules or {})
	table.insert(matrix, row)
end

local main = function()
	common.enforce_http_method("GET")
	local database = common.open_database("cgi-bin/machine.db")
	local first_day = extract_extreme_day(database, "ASC")
	local last_day = extract_extreme_day(database, "DESC")
	local matrix = {}
	local json = {}
	if first_day and last_day then
		local rules = extract_rules(database, first_day, last_day)
		local day_lt = extract_day_lt(database)
		local day_count = common.datediff(last_day, first_day) + 1
		each(function(i) process_day(matrix, add_days(first_day, i - 1), rules, day_lt) end, range(day_count))

		json.first_day = first_day
		json.last_day = last_day
		json.rules = common.collect_database(database, "SELECT name FROM rule ORDER BY order_priority ASC")
		json.matrix = matrix
	end
	local response = cjson.encode(json)
	common.respond(response)
	database:close()
end

main()
