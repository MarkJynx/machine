#!/usr/bin/env lua

local common = require("cgi-bin.common")
local cjson = require("cjson.safe")


local main = function()
	common.enforce_http_method("GET")
	local database = common.open_database("cgi-bin/machine.db")
	local rules = common.collect_database(database, "SELECT * FROM rule ORDER BY order_priority ASC")
	local response = cjson.encode(rules) or "null"
	common.respond(response)
end

main()
