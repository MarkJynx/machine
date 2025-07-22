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

	if not common.validate_day(day) then
		return nil
	end

	return day
end

local main = function()
	common.enforce_http_method("POST")
	local payload = common.extract_valid_date_payload(common.extract_content_length())
	local database = common.open_database("cgi-bin/machine.db")
	local response = "null"
	if common.day_exists(database, payload) then
		response = cjson.encode(extract_day(database, payload)) or "null"
	end
	common.respond(response)
	database:close()
end

main()
