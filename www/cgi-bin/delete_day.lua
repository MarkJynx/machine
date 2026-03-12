#!/usr/bin/env lua

local c = require("cgi-bin.common")

local response = c.db_delete_day(c.http_enforce_date_payload()) and "true" or "false"
c.db_backup()
c.http_respond(response)

