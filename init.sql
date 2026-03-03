PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS rule (
	name TEXT PRIMARY KEY, -- noun
	order_priority INTEGER NOT NULL UNIQUE CHECK(order_priority > 0),
	tier INTEGER NOT NULL CHECK(tier > 0),
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

INSERT INTO rule (name, order_priority, tier, period, weekdays) VALUES ("Early rise", 1, 1, 1, 127);
INSERT INTO rule (name, order_priority, tier, period, weekdays) VALUES ("Nail care", 2, 1, 7, 127);
INSERT INTO rule (name, order_priority, tier, period, weekdays) VALUES ("Home cleaning", 3, 1, 1, 127);
INSERT INTO rule (name, order_priority, tier, period, weekdays) VALUES ("Shower", 4, 1, 4, 127);
INSERT INTO rule (name, order_priority, tier, period, weekdays) VALUES ("Hair care", 5, 1, 2, 127);
INSERT INTO rule (name, order_priority, tier, period, weekdays) VALUES ("Face shave", 6, 1, 2, 127);
-- INSERT INTO rule (name, order_priority, tier, period, weekdays) VALUES ("Face care", 7);
INSERT INTO rule (name, order_priority, tier, period, weekdays) VALUES ("Dental care (after sleep)", 8, 1, 1, 127);
-- INSERT INTO rule (name, order_priority, tier, period, weekdays) VALUES ("Fresh clothes", 9);
-- INSERT INTO rule (name, order_priority, tier, period, weekdays) VALUES ("Productivity", 10);
-- INSERT INTO rule (name, order_priority, tier, period, weekdays) VALUES ("Car care", 11);
INSERT INTO rule (name, order_priority, tier, period, weekdays) VALUES ("Workout: push (A)", 12, 1, 7, 127);
INSERT INTO rule (name, order_priority, tier, period, weekdays) VALUES ("Workout: push (B)", 13, 2, 7, 127);
INSERT INTO rule (name, order_priority, tier, period, weekdays) VALUES ("Workout: pull (A)", 14, 1, 7, 127);
INSERT INTO rule (name, order_priority, tier, period, weekdays) VALUES ("Workout: pull (B)", 15, 2, 7, 127);
INSERT INTO rule (name, order_priority, tier, period, weekdays) VALUES ("Workout: legs (A)", 16, 1, 7, 127);
INSERT INTO rule (name, order_priority, tier, period, weekdays) VALUES ("Workout: legs (B)", 17, 2, 7, 127);
-- INSERT INTO rule (name, priority, tier, period, weekdays) VALUES ("Workout: core", 18);
-- INSERT INTO rule (name, priority, tier, period, weekdays) VALUES ("Workout: cardio", 19);
-- INSERT INTO rule (name, priority, tier, period, weekdays) VALUES ("Cooking", 20);
-- INSERT INTO rule (name, priority, tier, period, weekdays) VALUES ("Laundry", 21);
-- INSERT INTO rule (name, priority, tier, period, weekdays) VALUES ("Body care", 22);
-- INSERT INTO rule (name, priority, tier, period, weekdays) VALUES ("Dental care (before sleep)", 23);
-- INSERT INTO rule (name, priority, tier, period, weekdays) VALUES ("Homemade food", 24);
-- INSERT INTO rule (name, priority, tier, period, weekdays) VALUES ("Diet", 25); -- TODO: probably should be merged with homemade food
