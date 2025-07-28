#!/usr/bin/env lua

require("fun")()
local common = require("cgi-bin.common")
local cjson = require("cjson.safe")


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
	local row = reduce(function(a, r) return process_day_rule(a, date, r, day_lt) end, {}, rules)
	table.insert(matrix, row)
end

local main = function()
	common.http_enforce_method("GET")
	local json = common.db_read_deep()
	json.matrix = {}

	-- TODO: warn about scheduled not-done spots without not-done rule instances
	if json.day_first and json.day_last then
		local day_count = common.date_diff(json.day_last, json.day_first) + 1
		each(function(i) process_day(json.matrix, common.date_add(json.day_first, i - 1), json.rules, json.day_lt) end, range(day_count))
	end
	local response = cjson.encode(json)
	common.http_respond(response)
end

main()
