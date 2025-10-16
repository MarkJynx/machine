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

local date_in_schedule(date, schedule)
	-- TODO
end

local date_range_in_schedule(date, count, schedule)
	local dates = map(function(x) return common.date_add(date, i - 1) end, range(count))
	return any(function(date) return date_in_schedule(date, schedule) end, dates)
end

local process_week_rule(row, date, rule, day_lt)
	local schedule = reduce(function(a, s) if a then return a end if date_range_in_schedule(date, 7, s) then return s end, rule.schedules)
	end
	local rule_schedule
	local rule_period
	-- TODO: extract schedule
	-- TODO: extract perior
	-- TODO: priority 1: grey
	-- TODO: priority 2: dark green
	-- TODO: priority 3: green
	-- TODO: priority 4: yellow
	-- TODO: priority 5: red
end

local process_week = function(matrix, date, rules, day_lt, day_first)
	-- TODO: make last week day configurable, not hard-coded to 7
	if common.date_weekday(date) ~= 7 then
		return
	end

	local first_week_day_date = common.date_add(date, -7)
	if common.date_diff(first_week_day_date, day_first) < 0 then
		return
	end

	local row = reduce(function(a, r) return process_week_rule(a, first_week_day_date, r, day_lt) end, {}, rules)
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
		each(function(i) process_day(json.matrix, common.date_add(json.day_first, i - 1), json.rules, json.day_lt) end, range(day_count))
		each(function(i) process_week(json.week_matrix, common.date_add(json.day_first, i - 1), json.rules, json.day_lt) end, range(day_count))
	end
	local response = cjson.encode(json)
	common.http_respond(response)
end

main()
