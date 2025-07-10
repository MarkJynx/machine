#!/usr/bin/env lua

local common = require("cgi-bin.common")

local get_rules = function(db)
	-- TODO 1
	return nil
end

local get_rule_schedule = function(db, rule)
	-- TODO 2
	return nil
end

local rule_applies = function(db, rule_schedule)
	-- TODO 3
	return nil
end

local main = function()
	local payload = common.extract_valid_payload(common.extract_content_length())
	local database = common.open_database("cgi-bin/machine.db")
	if common.day_exists(database, payload) then
		common.respond("null")
	else
		local day = { id = payload, rule_instances = {} }
		local rules = get_rules(database)
		for _, rule in ipairs(rules) do
			local rule_schedule = get_rule_schedule(database, rule)
			if rule_applies(database, rule_schedule) then
				table.insert(day.rule_instances, { rule_name = rule.name, done = 0 })
			end
		end
		common.respond(common.day_to_json(day))
	end
end

main()
