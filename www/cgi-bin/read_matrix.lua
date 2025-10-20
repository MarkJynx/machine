#!/usr/bin/env lua

require("fun")()
local common = require("cgi-bin.common")
local cjson = require("cjson.safe")


local process_day_rule = function(row, date, rule, day_lt)
	if not day_lt[date] then
		table.insert(row, -3)
	elseif rule.schedule_lt[date] == nil then
		table.insert(row, rule.done_lt[date] and -1 or -2)
	else
		local done = rule.done_lt[date] and 1 or 0
		local mandatory = rule.schedule_lt[date] and 2 or 0
		table.insert(row, done + mandatory)
	end
	return row
end

local process_day = function(matrix, date, rules, day_lt)
	local row = reduce(function(a, r) return process_day_rule(a, date, r, day_lt) end, {}, rules)
	table.insert(matrix, row)
end

local date_in_schedule = function(date, schedule)
	local start_ok = common.date_diff(date, schedule.start_date) >= 0
	local end_ok = true
	if schedule.stop_date then
		end_ok = common.date_diff(schedule.stop_date, date) >= 0
	end
	-- TODO: weekday_ok?
	return start_ok and end_ok
end

local date_range_in_schedule = function(date, count, schedule)
	local dates = map(function(i) return common.date_add(date, i - 1) end, range(count))
	return any(function(date) return date_in_schedule(date, schedule) end, dates)
end

local process_week_rule = function(row, rule_row, date, rule)
	-- TODO: handle multiple applicable schedules
	local schedule = reduce(function(a, s) if a then return a end if date_range_in_schedule(date, 7, s) then return s end end, nil, rule.schedules)
	local grey_count = reduce(function(a, cell) if cell < 0 then return a + 1 end return a end, 0, rule_row)
	local done_count = reduce(function(a, cell) if cell == 1 or cell == 3 then return a + 1 end return a end, 0, rule_row)
	local yr_count = reduce(function(a, cell) if cell == 0 or cell == 1 or cell == 3 then return a + 1 end return a end, 0, rule_row)
	if grey_count >= 4 then
		table.insert(row, -1)
	elseif yr_count >= 7 then
		table.insert(row, 1) -- done, not mandatory
	elseif (schedule.period == 7 and done_count > 0) or (schedule.period ~= 7 and yr_count == 6) then
		table.insert(row, 3) -- done, mandatory
	elseif schedule.period ~= 7 and yr_count >= 4 then
		table.insert(row, 0) -- yellow
	else
		table.insert(row, 2) -- red
	end
	return row
end

local process_week = function(matrix, day_matrix, date, rules, day_first)
	-- TODO: make last week day configurable, not hard-coded to 7
	if common.date_weekday(date) ~= 7 then
		return
	end

	local first_week_day = common.date_add(date, -6)
	if common.date_diff(first_week_day, day_first) < 0 then
		return
	end
	date = first_week_day

	local row = {}
	for rule_index, rule in ipairs(rules) do
		local rule_row = {}  -- TODO: make a one-liner
		local day_base_index = common.date_diff(date, day_first)
		for day_index = 1, 7 do
			table.insert(rule_row, day_matrix[day_base_index + day_index][rule_index])
		end
		process_week_rule(row, rule_row, date, rule)
	end

	table.insert(matrix, row)
end

local main = function()
	common.http_enforce_method("GET")
	local json = common.db_read_deep()
	json.matrix = {}
	json.week_matrix = {}

	-- TODO: warn about scheduled not-done spots without not-done rule instances
	if json.day_first and json.day_last then
		local day_count = common.date_diff(json.day_last, json.day_first) + 1
		each(function(i)
			process_day(json.matrix, common.date_add(json.day_first, i - 1), json.rules, json.day_lt)
			process_week(json.week_matrix, json.matrix, common.date_add(json.day_first, i - 1), json.rules, json.day_first)
		end, range(day_count))
	end
	local response = cjson.encode(json)
	common.http_respond(response)
end

main()
