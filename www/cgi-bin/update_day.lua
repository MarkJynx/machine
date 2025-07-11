#!/usr/bin/env lua

local common = require("cgi-bin.common")
local cjson = require("cjson.safe")


local rule_instance_to_insert_query = function(rule_instance, day_id, database)
	local q = {}
	table.insert(q, "INSERT OR ROLLBACK INTO rule_instance")
	table.insert(q, "(rule_name, day_id, done, order_priority) VALUES (")
	table.insert(q, "'" .. database:escape(rule_instance.rule_name) .. "',")
	table.insert(q, string.format("'%s',%d,%d)", day_id, rule_instance.done, rule_instance.order_priority))
	return table.concat(q)
end

local main = function()
	local content_length = common.extract_content_length()
	local payload = nil
	if content_length > 0 then
		payload = io.read(content_length)
	end
	local day = cjson.decode(payload)
	local database = common.open_database("cgi-bin/machine.db")

	if day and not common.day_exists(database, day.id) and common.validate_day(day) then
		local s = {}
		table.insert(s, "PRAGMA foreign_keys = ON")
		table.insert(s, "BEGIN TRANSACTION")
		table.insert(s, "DELETE FROM rule_instance WHERE day_id = '" .. day.id .. "'")
		table.insert(s, "DELETE FROM day WHERE id = '" .. day.id .. "'")
		local notes = "NULL"
		if day.notes then
			notes = "'" .. database:escape(day.notes) .. "'"
		end
		table.insert(s, "INSERT OR ROLLBACK INTO day ( id, notes) VALUES ( '" .. day.id .. "', " .. notes .. ')')

		if day.rule_instances then
			for _, rule_instance in ipairs(day.rule_instances) do
				table.insert(s, rule_instance_to_insert_query(rule_instance, day.id, database))
			end

		end

		table.insert(s, "COMMIT")

		local success = true
		for _, q in ipairs(s) do
			local result = database:execute(q)
			if not result then
				success = false
				break
			end
		end

		if success then
			common.respond("true")
		else
			common.respond("false")
		end
	else
		common.respond("false")
	end

	database:close()
end

main()
