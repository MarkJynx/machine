#!/usr/bin/env lua

local common = require("cgi-bin.common")
local cjson = require("cjson.safe")


local main = function()
	local content_length = common.extract_content_length()
	local payload = nil
	if content_length > 0 then
		payload = io.read(content_length)
	end
	local day = cjson.decode(payload)
	local database = common.open_database("cgi-bin/machine.db")

	if common.validate_day(day) then
		s = {}
		table.insert(s, "BEGIN TRANSACTION")
		table.insert(s, "DELETE FROM rule_instance WHERE day_id = '" .. day.id .. "'")
		table.insert(s, "DELETE FROM day WHERE id = '" .. day.id .. "'")
		local notes = "NULL"
		if day.notes then
			notes = "'" .. database:escape(day.notes) .. "'"
		end
		table.insert(s, "INSERT OR ROLLBACK INTO day ( id, notes) VALUES ( '" .. day.id .. "', " .. notes .. ')')
		for _, rule_instance in ipairs(day.rule_instances) do
			-- TODO: refactor into a function
			local q = {}
			table.insert(q, "INSERT OR ROLLBACK INTO rule_instance")
			table.insert(q, "(rule_name, day_id, done, order_priority) VALUES (")
			table.insert(q, "'" .. database:escape(rule_instance.rule_name) .. "',")
			table.insert(q, string.format("'%s',%d,%d)", day.id, rule_instance.done, rule_instance.order_priority))
			table.insert(s, table.concat(q, " "))
		end
		table.insert(s, "COMMIT")

		-- TODO: execute

		common.respond("true")
	else
		common.respond("false")
	end

	database:close()
end

main()
