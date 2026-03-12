#!/usr/bin/env lua

require("fun")()
local c = require("cgi-bin.common")
local cjson = require("cjson.safe")

local RULE_DAY_OFF = -2
local RULE_OFF = -1
local RULE_DUE_NOT_DONE = 2
local RULE_DUE_AND_DONE = 3
local RULE_NOT_DUE_NOT_DONE = 0
local RULE_NOT_DUE_BUT_DONE = 1
local TOLERABLE_FAILURE_RATE = 1

local process_day_rule = function(row, date, due_lt, done_lt, day_lt)
	if not day_lt[date] then
		table.insert(row, RULE_DAY_OFF)
	elseif due_lt[date] == nil then
		table.insert(row, RULE_OFF)
	else
		if done_lt[date] == false then
			table.insert(row, RULE_DUE_NOT_DONE)
		elseif done_lt[date] == true  then
			table.insert(row, due_lt[date] and RULE_DUE_AND_DONE or RULE_NOT_DUE_BUT_DONE)
		elseif done_lt[date] == nil then
			table.insert(row, due_lt[date] and RULE_DUE_NOT_DONE or RULE_NOT_DUE_NOT_DONE)
		end
	end
	return row
end

local process_day = function(date, rules, day_lt)
	return reduce(function(a, r) return process_day_rule(a, date, r.due_lt, r.done_lt, day_lt) end, {}, rules)
end

local process_week_rule = function(row, rule_row, rule_is_weekly)
	local off_count = reduce(function(a, rule) return (rule == RULE_DAY_OFF or rule == RULE_OFF) and a + 1 or a end, 0, rule_row)
	local done_count = reduce(function(a, rule) return (rule == RULE_NOT_DUE_BUT_DONE or rule == RULE_DUE_AND_DONE) and a + 1 or a end, 0, rule_row)
	local due_not_done_count = reduce(function(a, rule) return rule == RULE_DUE_NOT_DONE and a + 1 or a end, 0, rule_row)
	local bad_count = due_not_done_count + off_count

	if off_count >= 7 or (done_count + due_not_done_count <= 0) or (not rule_is_weekly and off_count >= TOLERABLE_FAILURE_RATE + 1) then
		table.insert(row, RULE_OFF) -- vacation
	elseif bad_count <= 0 then
		table.insert(row, RULE_NOT_DUE_BUT_DONE) -- perfection, optional
	elseif (rule_is_weekly and done_count >= 1) or (not rule_is_weekly and bad_count <= TOLERABLE_FAILURE_RATE) then
		table.insert(row, RULE_DUE_AND_DONE) -- success (tolerable failure rate)
	else
		table.insert(row, RULE_DUE_NOT_DONE) -- failure (intolerable failure rate)
	end

	return row
end

local process_week = function(day_matrix, first_week_day, rules, day_first)
	return reduce(function(a, ri)
		local day_base_index = math.tointeger(c.date_diff(first_week_day, day_first))
		local rule_row = totable(map(function(i) return day_matrix[day_base_index + i][ri] end, range(7)))
		return process_week_rule(a, rule_row, rules[ri].period == 7)
	end, {}, range(#rules))
end

local main = function()
	c.http_enforce_method("GET")
	local json = c.db_read_deep()
	json.matrix_labels = totable(map(function(i) return c.date_add(json.day_first, i - 1) end, range(json.day_count)))
	json.week_matrix_labels = totable(filter(function(d) return c.date_weekday(d) == 1 and c.date_add(d, 6) <= json.day_last end, json.matrix_labels))
	json.matrix = totable(map(function(date) return process_day(date, json.rules, json.day_lt) end, json.matrix_labels))
	json.week_matrix = totable(map(function(date) return process_week(json.matrix, date, json.rules, json.day_first) end, json.week_matrix_labels))
	c.http_respond(cjson.encode(json) or "null")
end

main()
