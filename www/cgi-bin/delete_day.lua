#!/usr/bin/env lua

local common = require("cgi-bin.common")


local main = function()
	local date = common.http_enforce_date_payload()
	local response = common.db_delete_day(date) and "true" or "false"
	common.db_backup()
	common.http_respond(response)
end

main()
