#!/usr/bin/env lua

require("fun")()
local common = require("cgi-bin.common")
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

local process_day = function(labels, matrix, date, rules, day_lt)
	local row = reduce(function(a, r) return process_day_rule(a, date, r.due_lt, r.done_lt, day_lt) end, {}, rules)
	table.insert(labels, date)
	table.insert(matrix, row)
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

local process_week = function(labels, matrix, day_matrix, date, rules, day_first)
	-- TODO: make last week day configurable, not hard-coded to 7
	if common.date_weekday(date) ~= 7 then
		return
	end

	local first_week_day = common.date_add(date, -6)
	if common.date_diff(first_week_day, day_first) < 0 then
		return
	end

	local row = reduce(function(a, ri)
		local day_base_index = math.tointeger(common.date_diff(first_week_day, day_first))
		local rule_row = totable(map(function(i) return day_matrix[day_base_index + i][ri] end, range(7)))
		return process_week_rule(a, rule_row, rules[ri].period == 7)
	end, {}, range(#rules))

	table.insert(labels, first_week_day)
	table.insert(matrix, row)
end

local main = function()
	common.http_enforce_method("GET")
	local json = common.db_read_deep()
	json.matrix_labels, json.matrix, json.week_matrix_labels, json.week_matrix = {}, {}, {}, {}

	if json.day_first and json.day_last then
		local day_count = common.date_diff(json.day_last, json.day_first) + 1
		each(function(i)
			process_day(json.matrix_labels, json.matrix, common.date_add(json.day_first, i - 1), json.rules, json.day_lt)
			process_week(json.week_matrix_labels, json.week_matrix, json.matrix, common.date_add(json.day_first, i - 1), json.rules, json.day_first)
		end, range(day_count))
	end
	local response = cjson.encode(json)
	common.http_respond(response)
end

main()
