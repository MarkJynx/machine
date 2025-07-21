#!/usr/bin/env lua

local common = require("cgi-bin.common")


local process_day = function(day_id, database)
	print(string.format('INSERT INTO day (id) VALUES ("%s");', day_id))
	local q = "SELECT * FROM rule_instance WHERE day_id = '" .. day_id .. "' ORDER BY order_priority ASC"
	local rule_instances = common.collect_database(database, q)
	for _, r in ipairs(rule_instances or {}) do
		local s = "INSERT INTO rule_instance (rule_name, rule_schedule_id, day_id, done, order_priority) VALUES ("
		local padding = string.rep(" ", 25 - #r.rule_name)
		s = s .. string.format('"%s",%s %2d, "%s", %d, %d);', r.rule_name, padding, r.rule_schedule_id, r.day_id, r.done, r.order_priority)
		print(s)
	end
	print()
end

local database = common.open_database("cgi-bin/machine.db")
local days = common.collect_database(database, "SELECT * FROM day ORDER BY JULIANDAY(id) ASC")
for _, day in ipairs(days or {}) do
	process_day(day.id, database)
end
database:close()
