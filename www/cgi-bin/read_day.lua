#!/usr/bin/env lua

local common = require("cgi-bin.common")
local cjson = require("cjson.safe")


local extract_day = function(db, id)
	-- TODO: validate anything you get from database
	local day = common.collect_single_record(db, "SELECT * FROM day WHERE id = '" .. id .. "'")
	if not day then
		return nil
	end

	-- TODO: validate anything you get from database
	local query = "SELECT * FROM rule_instance WHERE day_id = '" .. id .. "' ORDER BY order_priority ASC"
	day.rule_instances = common.collect_database(db, query)

	return day
end

local main = function()
	local date = common.enforce_date_payload()
	local database = common.open_database("cgi-bin/machine.db")
	local response = "null"
	if common.day_exists(database, date) then
		response = cjson.encode(extract_day(database, date)) or "null"
	end
	common.respond(response)
	database:close()
end

main()
