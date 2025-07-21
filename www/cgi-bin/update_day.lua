#!/usr/bin/env lua

local common = require("cgi-bin.common")
local cjson = require("cjson.safe")


local assign_rule_schedules = function(day, database)
	if not day or not day.rule_instances then
		return false
	end

	for _, i in ipairs(day.rule_instances) do
		i.rule_schedule = common.get_rule_schedule(database, i.rule_name, i.day_id)
		if not i.rule_schedule then
			return false
		end
	end

	return true
end

local rule_instance_to_insert_query = function(rule_instance, day_id, database)
	local q = {}
	table.insert(q, "INSERT OR ROLLBACK INTO rule_instance")
	table.insert(q, "(rule_name, rule_schedule_id, day_id, done, order_priority) VALUES (")
	table.insert(q, "'" .. database:escape(rule_instance.rule_name) .. "',")
	table.insert(q, tostring(rule_instance.rule_schedule.id))
	table.insert(q, string.format("'%s',%d,%d)", day_id, rule_instance.done, rule_instance.order_priority))
	return table.concat(q)
end

local database_to_sql_day = function(day_id, database, sql_script)
	sql_script:write(string.format('INSERT INTO day (id) VALUES ("%s");\n', day_id))

	local q = "SELECT * FROM rule_instance WHERE day_id = '" .. day_id .. "' ORDER BY order_priority ASC"
	local rule_instances = common.collect_database(database, q)
	for _, r in ipairs(rule_instances or {}) do
		local s = "INSERT INTO rule_instance (rule_name, rule_schedule_id, day_id, done, order_priority) VALUES ("
		-- TODO: dynamic padding
		local rule_name = '"' .. r.rule_name .. '",' .. string.rep(" ", 26 - #r.rule_name)
		s = s .. string.format('%s%2d, "%s", %d, %2d);\n', rule_name, r.rule_schedule.id, r.day_id, r.done, r.order_priority)
		sql_script:write(s)
	end
end

local database_to_sql = function (database, sql_path)
	local sql_script = io.open(sql_path, "wb")
	local days = common.collect_database(database, "SELECT * FROM day ORDER BY JULIANDAY(id) ASC")
	for index, day in ipairs(days or {}) do
		database_to_sql_day(day.id, database, sql_script)
		if index ~= #days then
			sql_script:write("\n")
		end
	end
	sql_script:close()
end

local main = function()
	common.enforce_http_method("POST")
	local content_length = common.extract_content_length()
	local payload = nil
	if content_length > 0 then
		payload = io.read(content_length)
	end
	local day = cjson.decode(payload)
	local database = common.open_database("cgi-bin/machine.db")
	local response = "false"
	local schedules_assigned = assign_rule_schedules(day, database)

	if day and common.validate_day(day) and schedules_assigned then
		local s = {}
		table.insert(s, "PRAGMA foreign_keys = ON")
		table.insert(s, "BEGIN TRANSACTION")
		table.insert(s, "DELETE FROM rule_instance WHERE day_id = '" .. day.id .. "'")
		table.insert(s, "DELETE FROM day WHERE id = '" .. day.id .. "'")
		local notes = "NULL"
		if type(day.notes) == "string" then
			notes = "'" .. database:escape(day.notes) .. "'"
		end
		table.insert(s, "INSERT OR ROLLBACK INTO day ( id, notes) VALUES ( '" .. day.id .. "', " .. notes .. ')')

		if day.rule_instances then
			for _, rule_instance in ipairs(day.rule_instances) do
				table.insert(s, rule_instance_to_insert_query(rule_instance, day.id, database))
			end

		end

		table.insert(s, "COMMIT")

		if common.execute_many_database_queries(database, s) then
			response = "true"
		end
	end

	database_to_sql(database, "cgi-bin/machine.sql")

	common.respond(response)
	database:close()
end

main()
