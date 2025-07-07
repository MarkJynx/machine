PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS category (
	name TEXT PRIMARY KEY,
	description TEXT NOT NULL UNIQUE,
	motivation TEXT NOT NULL UNIQUE,
	color INTEGER NOT NULL UNIQUE CHECK(color >= 0 AND color <= 0xFFFFFF)
);

INSERT INTO category (name, description, motivation, color) VALUES (
	"Image (internal)",
	"One's immediate appearance and behavior",
	"Feeling well about one's appearance."                        || char(10) ||
	"Feeling well about how others perceive one's appearance."    || char(10) ||
	"Feeling well about one's behavior."                          || char(10) ||
	"Feeling well about how others perceive one's behavior.",
	0x0000FF
);

INSERT INTO category (name, description, motivation, color) VALUES (
	"Image (external)",
	"One's immediate surroundings",
	"Feeling well about one's surroundings."                      || char(10) ||
	"Feeling well about how others perceive one's surroundings.",
	0x000080
);

INSERT INTO category (name, description, motivation, color) VALUES (
	"Bodybuilding",
	"Building a better body",
	"Looks. Health. Strength. Endurance.",
	0xFF0000
);

-- TODO: ensure no gaps between order_priority entries
CREATE TABLE IF NOT EXISTS task (
	name TEXT PRIMARY KEY,
	category_name TEXT NOT NULL,
	description TEXT NOT NULL UNIQUE,
	motivation TEXT NOT NULL UNIQUE,
	tier INTEGER NOT NULL CHECK(tier > 0),
	order_priority INTEGER NOT NULL UNIQUE CHECK(order_priority > 0),
	points INTEGER NOT NULL CHECK(points > 0),
	color INTEGER NOT NULL UNIQUE CHECK(color >= 0 and color <= 0xFFFFFF),
	FOREIGN KEY (category_name) REFERENCES category (name)
);

INSERT INTO task (name, category_name, description, motivation, tier, order_priority, points, color) VALUES (
	"Wake early",
	"Image (internal)",
	"Rise from bed at 08:00 or earlier",
	"No more embarrassment of being late at work."                                  || char(10) ||
	"No more skipping morning chores and feeling bad afterwards."                   || char(10) ||
	"No more being stressed and in a hurry in the morning."                         || char(10) ||
	"Ability to relax, focus and have time for oneself before diving into the day." || char(10) ||
	"Margin for error in case of unexpected events."                                || char(10) ||
	"More useful (daylight, stores still open) time available during the day."      || char(10) ||
	"Good external image and work ethic.",
	1,
	1,
	10,
	0x0000FF
);

-- TODO: check against time overlaps for the same task_id
-- TODO: enforce YYYY-MM-DD format where applicable
CREATE TABLE IF NOT EXISTS task_schedule (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	task_name INTEGER NOT NULL,
	start_date TEXT NOT NULL, -- ISO-8601, YYYY-MM-DD
	end_date TEXT, -- ISO-8601, YYYY-MM-DD
	period INTEGER NOT NULL CHECK(period >= 1 AND period < 7), -- anything less frequent is not worthy to be a rule
	weekdays INTEGER NOT NULL CHECK(weekdays >= 0 AND weekdays <= 127), -- 7-bit integer, LSB is Monday, MSB is Sunday,
	notes TEXT,
	FOREIGN KEY (task_name) REFERENCES task (name)
);

-- TODO 2: shower
-- TODO 3: wash hair
-- TODO 4: dental care (after sleep)
-- TODO 5: shave face
-- TODO 6: clip nails
-- TODO 7: clean home
-- TODO 8: push
-- TODO 9: pull
-- TODO 10: legs

-- TODO 11: face care
-- TODO 12: dental care (before sleep)
-- TODO 13: shave body
-- TODO 14: fresh clothes
-- TODO 15: homemade food
-- TODO 16: laundry
-- TODO 17: car care
-- TODO 18: cooking
-- TODO 19: productivity
-- TODO 20: cardio
-- TODO 21: diet

-- TODO 22: hair care
-- TODO 23: budgeting
-- TODO 24: fighting
-- TODO 25: ...
