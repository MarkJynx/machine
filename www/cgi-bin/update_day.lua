#!/usr/bin/env lua

local common = require("cgi-bin.common")
local cjson = require("cjson.safe")


local main = function()
	local content_length = common.extract_content_length()
	local payload = nil
	if content_length > 0 then
		payload = io.read(content_length)
	end
	local day = cjson.decode(payload)
	io.stderr:write(cjson.encode(day))

	-- TODO: validate day.id, day.rule_instance[].day_id, day.rule_instance[].rule_name, day.rule_instance.done
	-- TODO: BEGIN, DELETE rule_instance, DELETE day, INSERT day
	-- TODO: INSERT rule_instance, COMMIT

	common.respond("false")
end

main()
