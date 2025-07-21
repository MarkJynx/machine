#!/usr/bin/env lua

local common = require("cgi-bin.common")
local cjson = require("cjson.safe")


local extract_rules = function(database)
	--1. 1. Extract rules.
	--1. 2. Extract rule schedule into rule.
	--1. 3. Extract rule_instance into rule.
end

local extract_extreme_day = function(database, order)
	local q = "SELECT day_id FROM rule_instance ORDER BY JULIANDAY(day_id) %s LIMIT 1"
	local rule_instance = common.collect_single_record(database, string.format(q, order))
	if rule_instance then
		return rule_instance.day_id
	end
	return nil
end

local main = function()
	common.enforce_http_method("GET")
	local database = common.open_database("cgi-bin/machine.db")
	local first_day = extract_extreme_day(database, "ASC")
	local last_day = extract_extreme_day(database, "DESC")
	io.stderr:write(string.format("%s .. %s\n", tostring(first_day), tostring(last_day)))
	local response = "null"
	common.respond(response)
	database:close()
end

main()

--1. 6. Iterate over days.
--1. 6. 1. If day is unavailable, fill with -1 and go to [2.6].
--1. 6. 2. Iterate over rules.
--1. 6. 2. 1. Check if applicable rule schedule exists. If not, fill with -1 and go to [2.6.2].
--1. 6. 2. 2. Check if mandatory (iterate over rule schedules & (last) instances).
--1. 6. 2. 3. Check if done (iterate over rule instances).
--1. 6. 2. 4. Return from 0 to 3.
--1. 7. Report results.
--1. 8. Front-end work...
