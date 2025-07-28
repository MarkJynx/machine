#!/usr/bin/env lua

local common = require("cgi-bin.common")


local response = common.db_delete_day(common.http_enforce_date_payload()) and "true" or "false"
common.db_backup()
common.http_respond(response)
