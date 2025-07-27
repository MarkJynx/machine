#!/usr/bin/env lua

local common = require("cgi-bin.common")
local cjson = require("cjson.safe")


local assign_rule_schedules = function(day, database)
	return all(function(i) i.rule_schedule = common.get_rule_schedule(database, i.rule_name, i.day_id) return i.rule_schedule ~= nil end, day.rule_instances)
end

local rule_instance_to_insert_query = function(rule_instance, day_id, database)
	local q = {}
	table.insert(q, "INSERT OR ROLLBACK INTO rule_instance")
	table.insert(q, "(rule_name, rule_schedule_id, day_id, done, order_priority) VALUES (")
	table.insert(q, "'" .. database:escape(rule_instance.rule_name) .. "',")
	table.insert(q, tostring(rule_instance.rule_schedule.id))
	table.insert(q, string.format(",'%s',%d,%d)", day_id, rule_instance.done, rule_instance.order_priority))
	return table.concat(q)
end

local main = function()
	common.http_enforce_method("POST")

	local content_length = common.http_extract_content_length()
	if content_length <= 0 then
		common.http_respond(nil)
	end

	local day = cjson.decode(io.read(content_length))
	if not day or day.id or assign_rule_schedules(day, database) then
		common.http_respond(nil)
	end

	local database = common.open_database("cgi-bin/machine.db")
	local response = "false"

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
	each(function(i) table.insert(s, rule_instance_to_insert_query(i, day.id, database)) end, day.rule_instances or {})
	table.insert(s, "COMMIT")

	if common.execute_many_database_queries(database, s) then
		response = "true"
		common.database_to_sql(database, "cgi-bin/machine.sql")
	end

	common.http_respond(response)
	database:close()
end

main()
