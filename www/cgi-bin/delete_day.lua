#!/usr/bin/env lua

local common = require("cgi-bin.common")


local delete_day = function(db, id)
	s = {}
	table.insert(s, "BEGIN TRANSACTION")
	table.insert(s, "DELETE FROM rule_instance WHERE day_id = '" .. id .. "'")
	table.insert(s, "DELETE FROM day WHERE id = '" .. id .. "'")
	table.insert(s, "COMMIT")
	for _, q in ipairs(s) do
		local result = db:execute(q)
		if not result then
			return false
		end
	end
	return true
end

local main = function()
	local payload = common.extract_valid_date_payload(common.extract_content_length())
	local database = common.open_database("cgi-bin/machine.db")
	if common.day_exists(database, payload) and delete_day(database, payload) then
		common.respond("true")
	else
		common.respond("false")
	end
	database:close()
end

main()
