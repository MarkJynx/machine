#!/usr/bin/env lua

local common = require("cgi-bin.common")

local extract_day = function(db, id)
	local query = "SELECT * FROM day WHERE id = '" .. id .. "'"
	local day = common.collect_database(db, query)
	if not day or #day > 1 then
		return nil
	end
	day = day[1]

	query = "SELECT * FROM rule_instance WHERE day_id = '" .. id .. "' ORDER BY order_priority ASC"
	day.rule_instances = common.collect_database(db, query)
	return day
end

local make_day_json = function(db, id)
	return common.day_to_json(extract_day(db, id))
end

local respond = function(json)
	io.write("Status: 200 OK\r\n")
	io.write("Content-Type: application/json;charset=utf-8\r\n")
	io.write("Content-Length: " .. #json .. "\r\n\r\n")
	io.write(json)
end

local main = function()
	local payload = common.extract_valid_payload(common.extract_content_length())
	local database = common.open_database("cgi-bin/machine.db")
	if common.day_exists(database, payload) then
		respond(make_day_json(database, payload))
	else
		respond("null")
	end
end

main()
