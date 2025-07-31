#!/bin/sh
rm -f www/cgi-bin/machine.db
sqlite3 www/cgi-bin/machine.db < init.sql
sqlite3 www/cgi-bin/machine.db < www/cgi-bin/machine.sql
