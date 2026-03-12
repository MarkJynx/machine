#!/usr/bin/env lua

require("fun")()
local c = require("cgi-bin.common")
local cjson = require("cjson.safe")

local rule_applies = function(r, d)
	return c.get_rule_weekdays(r)[c.date_weekday(d)] and (r.last_instance == nil and true or c.date_diff(d, r.last_instance.day_id) >= r.period)
end

local main = function()
	local date = c.http_enforce_date_payload()
	local shallow = c.db_read_shallow(date)
	c.http_panic(shallow.day ~= nil)
	local rules = totable(filter(function(r) return rule_applies(r, date) end, shallow.rules))
	local day = { id = date, rule_instances = reduce(function(a, r) table.insert(a, {rule_name = r.name, done = 0}) return a end, {}, rules) }
	c.http_respond(cjson.encode(day) or "null")
end

main()
