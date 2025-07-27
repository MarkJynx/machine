#!/usr/bin/env lua

require("fun")()
local common = require("cgi-bin.common")
local cjson = require("cjson.safe")


local extract_rule_done_lt = function(instances)
	return reduce(function(a, i) if i.done then a[i.day_id] = true end return a end, {}, instances)
end

local extract_rule_schedule_lt = function(lt, done_lt, schedule, first_day, last_day)
	local rule_schedule_weekdays = common.get_rule_schedule_weekdays(schedule)
	local start_date = max({schedule.start_date, first_day})
	local stop_date = schedule.stop_date and min({schedule.stop_day, last_day}) or last_day

	local day_count = common.date_diff(stop_date, start_date) + 1
	local not_done_streak = math.huge
	for i = 1, day_count do
		local current_date = common.date_add(start_date, i - 1)
		local date_weekday = common.date_weekday(current_date)
		lt[current_date] = schedule.period <= not_done_streak and rule_schedule_weekdays[date_weekday]
		not_done_streak = done_lt[current_date] and 1 or not_done_streak + 1
	end

	return lt
end

local extract_rule_schedule_lt_all = function(first_day, last_day, done_lt, schedules)
	return reduce(function(a, s) return extract_rule_schedule_lt(a, done_lt, s, first_day, last_day) end, {}, schedules)
end

local extract_rules = function(database, first_day, last_day)
	local rules = common.collect_database(database, "SELECT * FROM rule ORDER BY order_priority ASC")
	for _, rule in ipairs(rules or {}) do
		local selector = "WHERE rule_name = '" .. database:escape(rule.name) .. "'"
		local q1 = "SELECT * FROM rule_schedule " .. selector .. " ORDER BY JULIANDAY(start_date) ASC"
		local q2 = "SELECT * FROM rule_instance " .. selector .. " AND done = 1 ORDER BY JULIANDAY(day_id) ASC"
		rule.schedules = common.collect_database(database, q1)
		rule.instances = common.collect_database(database, q2)
		rule.done_lt = extract_rule_done_lt(rule.instances or {})
		rule.schedule_lt = extract_rule_schedule_lt_all(first_day, last_day, rule.done_lt, rule.schedules or {})
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
	local json = { matrix = {} }
	json.first_day = extract_extreme_day(database, "ASC")
	json.last_day = extract_extreme_day(database, "DESC")
	if json.first_day and json.last_day then
		local rules = extract_rules(database, json.first_day, json.last_day)
		local day_lt = extract_day_lt(database)
		local day_count = common.date_diff(json.last_day, json.first_day) + 1
		each(function(i) process_day(json.matrix, common.date_add(json.first_day, i - 1), rules, day_lt) end, range(day_count))
		json.rules = common.collect_database(database, "SELECT name FROM rule ORDER BY order_priority ASC")
	end
	local response = cjson.encode(json)
	common.respond(response)
	database:close()
end

main()
