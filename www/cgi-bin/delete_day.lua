#!/usr/bin/env lua

local common = require("cgi-bin.common")


local main = function()
	local date = common.http_enforce_date_payload()
	local response = "false"
	if common.db_delete_day(date) then
		response = "true"
	end
	common.http_respond(response)
	common.database_to_sql(database, "cgi-bin/machine.sql")
end

main()
