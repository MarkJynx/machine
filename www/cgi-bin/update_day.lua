#!/usr/bin/env lua

local common = require("cgi-bin.common")
local cjson = require("cjson.safe")


local main = function()
	common.http_enforce_method("POST")

	local content_length = common.http_extract_content_length()
	if content_length <= 0 then
		common.http_respond(nil)
	end

	local day = cjson.decode(io.read(content_length))
	if not day or not day.id then
		common.http_respond(nil)
	end

	local response = "false"

	common.db_insert_day(day)

	common.http_respond(response)
end

main()
