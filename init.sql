PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS rule (
	name TEXT PRIMARY KEY, -- noun
	order_priority INTEGER NOT NULL UNIQUE CHECK(order_priority > 0),
	period INTEGER NOT NULL CHECK(period >= 1 AND period <= 7), -- anything less frequent is not worthy to be a rule
	weekdays INTEGER NOT NULL CHECK(weekdays >= 0 AND weekdays <= 127) -- 7-bit integer, LSB is Monday, MSB is Sunday; NULL means all weekdays
) STRICT, WITHOUT ROWID;

CREATE TABLE IF NOT EXISTS day (
	id TEXT PRIMARY KEY CHECK(id IS date(id, "+0 days")),
	notes TEXT
) STRICT, WITHOUT ROWID;

CREATE TABLE IF NOT EXISTS rule_instance (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	rule_name TEXT NOT NULL,
	day_id TEXT NOT NULL,
	done INTEGER NOT NULL CHECK (done == 0 OR done == 1),
	order_priority INTEGER NOT NULL CHECK(order_priority > 0),
	FOREIGN KEY (rule_name) REFERENCES rule (name),
	FOREIGN KEY (day_id) REFERENCES day (id)
) STRICT;

---------------------------------------------------------------------------------------------------

INSERT INTO rule (name, order_priority, period, weekdays) VALUES ("Early rise", 1, 1, 127);
INSERT INTO rule (name, order_priority, period, weekdays) VALUES ("Nail care", 2, 7, 127);
INSERT INTO rule (name, order_priority, period, weekdays) VALUES ("Home cleaning", 3, 1, 127);
INSERT INTO rule (name, order_priority, period, weekdays) VALUES ("Shower", 4, 4, 127);
INSERT INTO rule (name, order_priority, period, weekdays) VALUES ("Hair care", 5, 2, 127);
INSERT INTO rule (name, order_priority, period, weekdays) VALUES ("Face shave", 6, 2, 127);
INSERT INTO rule (name, order_priority, period, weekdays) VALUES ("Dental care (after sleep)", 8, 1, 127);
INSERT INTO rule (name, order_priority, period, weekdays) VALUES ("Workout: push (A)", 12, 7, 127);
INSERT INTO rule (name, order_priority, period, weekdays) VALUES ("Workout: push (B)", 13, 7, 127);
INSERT INTO rule (name, order_priority, period, weekdays) VALUES ("Workout: pull (A)", 14, 7, 127);
INSERT INTO rule (name, order_priority, period, weekdays) VALUES ("Workout: pull (B)", 15, 7, 127);
INSERT INTO rule (name, order_priority, period, weekdays) VALUES ("Workout: legs (A)", 16, 7, 127);
INSERT INTO rule (name, order_priority, period, weekdays) VALUES ("Workout: legs (B)", 17, 7, 127);
