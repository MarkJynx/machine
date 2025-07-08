PRAGMA foreign_keys = ON;

-- TODO: make a precaution (REPLACE?) so one could run this script repetitively without errors

CREATE TABLE IF NOT EXISTS category (
	name TEXT PRIMARY KEY,
	description TEXT NOT NULL UNIQUE,
	motivation TEXT NOT NULL UNIQUE, -- always focus on the positives only
	color INTEGER NOT NULL UNIQUE CHECK(color >= 0 AND color <= 0xFFFFFF)
) WITHOUT ROWID;

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
-- TODO: consider sub-tasks
-- TODO: add color when needed
CREATE TABLE IF NOT EXISTS task (
	name TEXT PRIMARY KEY, -- noun
	category_name TEXT NOT NULL,
	description TEXT NOT NULL UNIQUE, -- verb
	motivation TEXT NOT NULL, -- always focus on the positives only
	tier INTEGER NOT NULL CHECK(tier > 0),
	order_priority INTEGER NOT NULL UNIQUE CHECK(order_priority > 0),
	points INTEGER NOT NULL CHECK(points > 0),
	FOREIGN KEY (category_name) REFERENCES category (name)
) WITHOUT ROWID;

INSERT INTO task (name, category_name, description, motivation, tier, order_priority, points) VALUES (
	"Waking early",
	"Image (internal)",
	"Rise from bed at 08:00 or earlier",
	"Ability to take a thorough and laid-back approach to morning chores."          || char(10) ||
	"Ability to relax and focus on oneself before diving into the day."             || char(10) ||
	"Margin for error in case of unexpected events."                                || char(10) ||
	"More useful time available during the day."                                    || char(10) ||
	"Good external image and work ethic.",
	1,
	1,
	10
);

INSERT INTO task (name, category_name, description, motivation, tier, order_priority, points) VALUES (
	"Shower",
	"Image (internal)",
	"Shower",
	"Feeling fresh and clean.",
	1,
	2,
	10
);

INSERT INTO task (name, category_name, description, motivation, tier, order_priority, points) VALUES (
	"Hair care",
	"Image (internal)",
	"Wash hair. Visit barber if deemed necessary. Apply products if deemed necessary.",
	"Looks. Style. Discipline & order.",
	1,
	3,
	6
);

INSERT INTO task (name, category_name, description, motivation, tier, order_priority, points) VALUES (
	"Dental care (after sleep)",
	"Image (internal)",
	"Brush teeth and wash mouth after sleep",
	"Looks. Smell. Health. Money.",
	1,
	4,
	2
);

INSERT INTO task (name, category_name, description, motivation, tier, order_priority, points) VALUES (
	"Face shaving",
	"Image (internal)",
	"Cleanly shave facial hair.",
	"Looks. Style. Discipline & order.",
	1,
	5,
	4
);

INSERT INTO task (name, category_name, description, motivation, tier, order_priority, points) VALUES (
	"Clip nails",
	"Image (internal)",
	"Check and (if deemed necessary) clip and file fingernails and toenails.",
	"Looks. Style. Discipline & order.",
	1,
	6,
	1
);

INSERT INTO task (name, category_name, description, motivation, tier, order_priority, points) VALUES (
	"Clean home",
	"Image (external)",
	"Clean apartment either until the looks or the amount of time and effort spent is deemed sufficient.",
	"Mood. Productivity. Image.",
	1,
	7,
	4
);

INSERT INTO task (name, category_name, description, motivation, tier, order_priority, points) VALUES (
	"Workout: push",
	"Bodybuilding",
	"Full bodybuilding pushing workout.",
	"Looks. Confidence. Health. Performance.",
	1,
	8,
	30
);

INSERT INTO task (name, category_name, description, motivation, tier, order_priority, points) VALUES (
	"Workout: pull",
	"Bodybuilding",
	"Full bodybuilding pulling workout.",
	"Looks. Confidence. Health. Performance.",
	1,
	9,
	30
);

INSERT INTO task (name, category_name, description, motivation, tier, order_priority, points) VALUES (
	"Workout: legs",
	"Bodybuilding",
	"Full bodybuilding leg workout.",
	"Looks. Confidence. Health. Performance.",
	1,
	10,
	30
);

INSERT INTO task (name, category_name, description, motivation, tier, order_priority, points) VALUES (
	"Face care",
	"Image (internal)",
	"Wash and moisturize face."
	"", -- TODO: motivation,
	2,
	100, -- TODO: order_priority,
	1 -- TODO: points
);

INSERT INTO task (name, category_name, description, motivation, tier, order_priority, points) VALUES (
	"Dental care (before sleep)",
	"Image (internal)",
	"Brush teeth and wash mouth after sleep",
	"", -- TODO: motivation,
	2,
	101, -- TODO: order_priority,
	1, -- TODO: points
);

INSERT INTO task (name, category_name, description, motivation, tier, order_priority, points) VALUES (
	"Body care",
	"Image (internal)",
	"Shave body. Trim nose hair if deemed necessary. Apply products if deemed necessary."
	"", -- TODO: motivation,
	2,
	102, -- TODO: order_priority,
	1, -- TODO: points
);

INSERT INTO task (name, category_name, description, motivation, tier, order_priority, points) VALUES (
	"Fresh clothes",
	"Image (internal)",
	"Dress up with a full set of fresh, clean, ironed clothes and wear perfume."
	"", -- TODO: motivation,
	2,
	103, -- TODO: order_priority,
	1, -- TODO: points
);

INSERT INTO task (name, category_name, description, motivation, tier, order_priority, points) VALUES (
	"Homemade food",
	"Image (external)",
	"Eat only homemade food throughout the day."
	"", -- TODO: motivation,
	2,
	104, -- TODO: order_priority,
	1, -- TODO: points
);

INSERT INTO task (name, category_name, description, motivation, tier, order_priority, points) VALUES (
	"Laundry",
	"Image (external)",
	"Do laundry.",
	"", -- TODO: motivation,
	2,
	105, -- TODO: order_priority,
	1, -- TODO: points
);

INSERT INTO task (name, category_name, description, motivation, tier, order_priority, points) VALUES (
	"Car care",
	"Image (external)",
	"Wash car. Fuel car. Charge car battery. Take car to car shop.",
	"", -- TODO: motivation,
	2,
	106, -- TODO: order_priority,
	1, -- TODO: points
);

INSERT INTO task (name, category_name, description, motivation, tier, order_priority, points) VALUES (
	"Cooking",
	"Image (external)",
	"Meal-prep for the upcoming days, weeks or even months.",
	"", -- TODO: motivation,
	2,
	107, -- TODO: order_priority,
	1, -- TODO: points
);

INSERT INTO task (name, category_name, description, motivation, tier, order_priority, points) VALUES (
	"Productivity",
	"Image (external)",
	"Be productive at work.",
	"", -- TODO: motivation,
	2,
	108, -- TODO: order_priority,
	1, -- TODO: points
);

INSERT INTO task (name, category_name, description, motivation, tier, order_priority, points) VALUES (
	"Diet",
	"Bodybuilding",
	"Maintain a proper diet appropriate to current bodybuilding phase throughout the day. Consistently track bodyweight.",
	"", -- TODO: motivation,
	2,
	109, -- TODO: order_priority,
	1, -- TODO: points
);

INSERT INTO task (name, category_name, description, motivation, tier, order_priority, points) VALUES (
	"Cardio",
	"Bodybuilding",
	"At least an hour of at least zone two cardio.",
	"", -- TODO: motivation,
	2,
	110, -- TODO: order_priority,
	1, -- TODO: points
);

-- TODO: check against time overlaps for the same task_id
-- TODO: enforce YYYY-MM-DD format where applicable
CREATE TABLE IF NOT EXISTS task_schedule (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	task_name INTEGER NOT NULL,
	start_date TEXT NOT NULL, -- ISO-8601, YYYY-MM-DD
	end_date TEXT, -- ISO-8601, YYYY-MM-DD
	period INTEGER NOT NULL CHECK(period >= 1 AND period < 7), -- anything less frequent is not worthy to be a rule
	weekdays INTEGER NOT NULL CHECK(weekdays >= 0 AND weekdays <= 127), -- 7-bit integer, LSB is Monday, MSB is Sunday; NULL means all weekdays
	notes TEXT,
	FOREIGN KEY (task_name) REFERENCES task (name)
);

INSERT INTO task_schedule (task_name, start_date, period, weekdays) VALUES (
	"Waking early",
	"2025-07-07",
	1,
	127
);

-- TODO: ensure no gaps between id entries?
-- TODO: generated columns
-- TODO: consider vacations
CREATE TABLE IF NOT EXISTS day (
	id TEXT PRIMARY KEY,
	notes TEXT
) WITHOUT ROWID;

-- TODO: ensure no gaps between order_priority entries for a day
CREATE TABLE IF NOT EXISTS chore (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	task_name TEXT NOT NULL,
	day_id TEXT NOT NULL,
	done INTEGER NOT NULL CHECK (done == 0 OR done == 1),
	order_priority INTEGER NOT NULL,
	FOREIGN KEY (task_name) REFERENCES task (name),
	FOREIGN KEY (day_id) REFERENCES day (id)
);
