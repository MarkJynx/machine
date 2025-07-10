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
		-- TODO: DELETE rule_instance
		-- TODO: DELETE day
		local notes = "NULL"
		if day.notes then
			notes = "'" .. database:escape(day.notes) .. "'"
		end
		-- TODO: INSERT day
		-- TODO: INSERT rule_instance, COMMIT
		table.insert(s, "COMMIT")

		common.respond("true")
	else
		common.respond("false")
	end

	database:close()
end

main()
