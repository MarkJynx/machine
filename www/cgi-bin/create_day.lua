#!/usr/bin/env lua

local common = require("cgi-bin.common")
local cjson = require("cjson.safe")


local get_rules = function(db)
	return common.collect_database(db, "SELECT * FROM rule ORDER BY order_priority ASC")
end

local get_last_rule_instance = function(db, rule)
	-- TODO: validate anything you get from database
	local q = "SELECT * FROM rule_instance WHERE rule_name = '" .. rule.name .. "' AND done = 1 ORDER BY JULIANDAY(day_id) DESC LIMIT 1"
	local rule_instance = common.collect_database(db, q)
	if not rule_instance or #rule_instance ~= 1 then
		return nil
	end
	return rule_instance[1]
end

local rule_applies = function(rule_schedule, last_rule_instance, date)
	if not rule_schedule then
		return false
	end

	local date_table = common.date_string_to_date_table(date)
	local date_weekday = os.date("%w", os.time(date_table)) + 1
	local rule_schedule_weekdays = { }
	for i = 1, 7 do
		rule_schedule_weekdays[i] = rule_schedule.weekdays & (2 ^ (i - 1))
	end
	if not rule_schedule_weekdays[date_weekday] then
		return false
	end

	if not last_rule_instance then
		return true
	end

	local old_date_table = common.date_string_to_date_table(last_rule_instance.day_id)
	local dt = os.difftime(os.time(date_table), os.time(old_date_table))
	if dt < rule_schedule.period * 86400 then
		return false
	end

	return true
end

local main = function()
	common.enforce_http_method("POST")
	local payload = common.extract_valid_date_payload(common.extract_content_length())
	local database = common.open_database("cgi-bin/machine.db")
	local response = "null"
	if payload and not common.day_exists(database, payload) then
		local day = { id = payload, rule_instances = {} }
		local rules = get_rules(database) or {}
		for _, rule in ipairs(rules) do
			local rule_schedule = common.get_rule_schedule(database, rule, payload)
			local last_rule_instance = get_last_rule_instance(database, rule)
			if rule_applies(rule_schedule, last_rule_instance, payload) then
				table.insert(day.rule_instances, { rule_name = rule.name, done = 0 })
			end
		end
		response = cjson.encode(day) or "null"
	end
	common.respond(response)
	database:close()
end

main()
