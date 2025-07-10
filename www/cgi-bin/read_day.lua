#!/usr/bin/env lua

local common = require("cgi-bin.common")
local cjson = require("cjson.safe")


local extract_day = function(db, id)
	-- TODO: validate anything you get from database
	local query = "SELECT * FROM day WHERE id = '" .. id .. "'"
	local day = common.collect_database(db, query)
	if not day or #day > 1 then
		return nil
	end
	day = day[1]

	-- TODO: validate anything you get from database
	query = "SELECT * FROM rule_instance WHERE day_id = '" .. id .. "' ORDER BY order_priority ASC"
	day.rule_instances = common.collect_database(db, query)
	return day
end

local respond = function(json)
	io.write("Status: 200 OK\r\n")
	io.write("Content-Type: application/json;charset=utf-8\r\n")
	io.write("Content-Length: " .. #json .. "\r\n\r\n")
	io.write(json)
end

local main = function()
	local payload = common.extract_valid_date_payload(common.extract_content_length())
	local database = common.open_database("cgi-bin/machine.db")
	if common.day_exists(database, payload) then
		respond(cjson.encode(extract_day(database, payload)))
	else
		respond("null")
	end
end

main()
