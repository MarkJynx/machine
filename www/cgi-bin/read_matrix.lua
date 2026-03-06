#!/usr/bin/env lua

require("fun")()
local common = require("cgi-bin.common")
local cjson = require("cjson.safe")


local TASK_DAY_OFF = -2
local TASK_OFF = -1
local TASK_DUE_NOT_DONE = 2
local TASK_DUE_AND_DONE = 3
local TASK_NOT_DUE_NOT_DONE = 0
local TASK_NOT_DUE_BUT_DONE = 1

local process_day_rule = function(row, date, due_lt, done_lt, day_lt)
	if not day_lt[date] then
		table.insert(row, TASK_DAY_OFF)
	elseif due_lt[date] == nil then
		table.insert(row, TASK_OFF)
	else
		if done_lt[date] == false then
			table.insert(row, TASK_DUE_NOT_DONE)
		elseif done_lt[date] == true  then
			table.insert(row, due_lt[date] and TASK_DUE_AND_DONE or TASK_NOT_DUE_BUT_DONE)
		elseif done_lt[date] == nil then
			table.insert(row, due_lt[date] and TASK_DUE_NOT_DONE or TASK_NOT_DUE_NOT_DONE)
		end
	end
	return row
end

local process_day = function(labels, matrix, date, rules, day_lt)
	local row = reduce(function(a, r) return process_day_rule(a, date, r.due_lt, r.done_lt, day_lt) end, {}, rules)
	table.insert(labels, date)
	table.insert(matrix, row)
end

local process_week_rule = function(row, rule_row, rule)
	local grey_count = reduce(function(a, cell) if cell < 0 then return a + 1 end return a end, 0, rule_row)
	local done_count = reduce(function(a, cell) if cell == 1 or cell == 3 then return a + 1 end return a end, 0, rule_row)
	local red_count = reduce(function(a, cell) if cell == 2 then return a + 1 end return a end, 0, rule_row)
	local bad_count = red_count + grey_count
	if grey_count >= 7 or (done_count <= 0 and red_count <= 0) then
		table.insert(row, -1) -- grey, this was a vacation week
	elseif bad_count <= 0 then
		table.insert(row, 1) -- deep green, perfection, done but not mandatory
	elseif (rule.period == 7 and done_count >= 1) or (rule.period ~= 7 and bad_count <= 1) then
		table.insert(row, 3) -- green, okay, done and mandatory, as it should be
	elseif rule.period ~= 7 and grey_count >= 2 then
		table.insert(row, -1) -- grey, this was a vacation week
	else
		table.insert(row, 2) -- red, failure
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
	date = first_week_day
	table.insert(labels, date)

	local row = {}
	for rule_index, rule in ipairs(rules) do
		local rule_row = {}  -- TODO: make a one-liner
		local day_base_index = math.tointeger(common.date_diff(date, day_first))
		for day_index = 1, 7 do
			table.insert(rule_row, day_matrix[day_base_index + day_index][rule_index])
		end
		process_week_rule(row, rule_row, rule)
	end

	table.insert(matrix, row)
end

local main = function()
	common.http_enforce_method("GET")
	local json = common.db_read_deep()
	json.matrix_labels = {}
	json.matrix = {}
	json.week_matrix_labels = {}
	json.week_matrix = {}

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
