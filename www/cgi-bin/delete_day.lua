#!/usr/bin/env lua

local common = require("cgi-bin.common")


local delete_day = function(db, id)
	local s = {}
	table.insert(s, "BEGIN TRANSACTION")
	table.insert(s, "DELETE FROM rule_instance WHERE day_id = '" .. id .. "'")
	table.insert(s, "DELETE FROM day WHERE id = '" .. id .. "'")
	table.insert(s, "COMMIT")
	return common.execute_many_database_queries(db, s)
end

local main = function()
	common.enforce_http_method("POST")
	local payload = common.extract_valid_date_payload(common.extract_content_length())
	local database = common.open_database("cgi-bin/machine.db")
	local response = "false"
	if common.day_exists(database, payload) and delete_day(database, payload) then
		response = "true"
	end
	common.respond(response)
	common.database_to_sql(database, "cgi-bin/machine.sql")
	database:close()
end

main()
