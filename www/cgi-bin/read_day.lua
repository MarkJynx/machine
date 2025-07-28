#!/usr/bin/env lua

local common = require("cgi-bin.common")
local cjson = require("cjson.safe")


local main = function()
	local date = common.http_enforce_date_payload()
	local day = common.db_read_shallow(date).day -- TODO: check if db_read_shallow() does not return nil
	local response = day and (cjson.encode(day) or "null") or "null"
	common.http_respond(response)
end

main()
