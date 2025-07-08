PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS rule_category (
	name TEXT PRIMARY KEY,
	description TEXT NOT NULL UNIQUE,
	motivation TEXT NOT NULL UNIQUE, -- always focus on the positives only
	color INTEGER NOT NULL UNIQUE CHECK(color >= 0 AND color <= 0xFFFFFF) -- TODO: use enumeration table
) WITHOUT ROWID;

-- TODO: ensure no gaps between order_priority entries
-- TODO: consider sub-rules
-- TODO: add color when needed
CREATE TABLE IF NOT EXISTS rule (
	name TEXT PRIMARY KEY, -- noun
	rule_category_name TEXT NOT NULL,
	rule_importance_label TEXT NOT NULL,
	description TEXT NOT NULL UNIQUE, -- verb
	motivation TEXT NOT NULL, -- always focus on the positives only
	tier INTEGER NOT NULL CHECK(tier > 0),
	order_priority INTEGER NOT NULL UNIQUE CHECK(order_priority > 0),
	FOREIGN KEY (rule_category_name) REFERENCES rule_category (name),
	FOREIGN KEY (rule_importance_label) REFERENCES rule_importance (label)
) WITHOUT ROWID;

-- TODO: check against time overlaps for the same rule_id
-- TODO: enforce YYYY-MM-DD format where applicable
CREATE TABLE IF NOT EXISTS rule_schedule (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	rule_name INTEGER NOT NULL,
	start_date TEXT NOT NULL, -- ISO-8601, YYYY-MM-DD
	end_date TEXT, -- ISO-8601, YYYY-MM-DD
	period INTEGER NOT NULL CHECK(period >= 1 AND period < 7), -- anything less frequent is not worthy to be a rule
	weekdays INTEGER NOT NULL CHECK(weekdays >= 0 AND weekdays <= 127), -- 7-bit integer, LSB is Monday, MSB is Sunday; NULL means all weekdays
	notes TEXT,
	FOREIGN KEY (rule_name) REFERENCES rule (name)
);

CREATE TABLE IF NOT EXISTS rule_importance (
	label TEXT PRIMARY KEY,
	value INTEGER NOT NULL UNIQUE CHECK(value > 0)
) WITHOUT ROWID;

-- TODO: ensure no gaps between id entries?
-- TODO: generated columns
-- TODO: consider vacations
CREATE TABLE IF NOT EXISTS day (
	id TEXT PRIMARY KEY,
	notes TEXT
) WITHOUT ROWID;

-- TODO: ensure no gaps between order_priority entries for a day
CREATE TABLE IF NOT EXISTS rule_instance (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	rule_name TEXT NOT NULL,
	day_id TEXT NOT NULL,
	done INTEGER NOT NULL CHECK (done == 0 OR done == 1),
	order_priority INTEGER NOT NULL,
	FOREIGN KEY (rule_name) REFERENCES rule (name),
	FOREIGN KEY (day_id) REFERENCES day (id)
);

---------------------------------------------------------------------------------------------------

-- TODO: make a precaution (REPLACE?) so one could run this script repetitively without errors

-- Four value Likert scale enumeration in regards to importance
INSERT INTO rule_importance (label, value) VALUES ( "Absolutely essential", 27);
INSERT INTO rule_importance (label, value) VALUES ( "Very important", 9);
INSERT INTO rule_importance (label, value) VALUES ( "Important", 3);
INSERT INTO rule_importance (label, value) VALUES ( "Slightly important", 1);

INSERT INTO rule_category (name, description, motivation, color) VALUES (
	"Image (internal)",
	"One's immediate appearance and behavior",
	"Feeling well about one's appearance."                        || char(10) ||
	"Feeling well about how others perceive one's appearance."    || char(10) ||
	"Feeling well about one's behavior."                          || char(10) ||
	"Feeling well about how others perceive one's behavior.",
	0x0000FF
);

INSERT INTO rule_category (name, description, motivation, color) VALUES (
	"Image (external)",
	"One's immediate surroundings",
	"Feeling well about one's surroundings."                      || char(10) ||
	"Feeling well about how others perceive one's surroundings.",
	0x000080
);

INSERT INTO rule_category (name, description, motivation, color) VALUES (
	"Bodybuilding",
	"Building a better body",
	"Looks. Health. Strength. Endurance.",
	0xFF0000
);

INSERT INTO rule (name, rule_category_name, rule_importance_label, description, motivation, tier, order_priority) VALUES (
	"Early rise",
	"Image (internal)",
	"Very important",
	"Rise from bed at 08:00 or earlier",
	"Ability to take a thorough and laid-back approach to morning chores."          || char(10) ||
	"Ability to relax and focus on oneself before diving into the day."             || char(10) ||
	"Margin for error in case of unexpected events."                                || char(10) ||
	"More useful time available during the day."                                    || char(10) ||
	"Good external image and work ethic.",
	1,
	1
);

INSERT INTO rule (name, rule_category_name, rule_importance_label, description, motivation, tier, order_priority) VALUES (
	"Shower",
	"Image (internal)",
	"Very important",
	"Shower",
	"Feeling fresh and clean.",
	1,
	2
);

INSERT INTO rule (name, rule_category_name, rule_importance_label, description, motivation, tier, order_priority) VALUES (
	"Hair care",
	"Image (internal)",
	"Important",
	"Wash hair. Visit barber if deemed necessary. Apply products if deemed necessary.",
	"Looks. Style. Discipline & order.",
	1,
	3
);

INSERT INTO rule (name, rule_category_name, rule_importance_label, description, motivation, tier, order_priority) VALUES (
	"Dental care (after sleep)",
	"Image (internal)",
	"Slightly important",
	"Brush teeth and wash mouth after sleep",
	"Looks. Smell. Health. Money.",
	1,
	4
);

INSERT INTO rule (name, rule_category_name, rule_importance_label, description, motivation, tier, order_priority) VALUES (
	"Face shave",
	"Image (internal)",
	"Important",
	"Cleanly shave facial hair.",
	"Looks. Style. Discipline & order.",
	1,
	5
);

INSERT INTO rule (name, rule_category_name, rule_importance_label, description, motivation, tier, order_priority) VALUES (
	"Nail care",
	"Image (internal)",
	"Slightly important",
	"Check and clip and file fingernails and toenails.",
	"Looks. Style. Discipline & order.",
	1,
	6
);

INSERT INTO rule (name, rule_category_name, rule_importance_label, description, motivation, tier, order_priority) VALUES (
	"Home cleaning",
	"Image (external)",
	"Important",
	"Clean home until results or effort spent is satisfactory.",
	"Mood. Productivity. Image.",
	1,
	7
);

INSERT INTO rule (name, rule_category_name, rule_importance_label, description, motivation, tier, order_priority) VALUES (
	"Workout: push",
	"Bodybuilding",
	"Absolutely essential",
	"Full bodybuilding pushing workout.",
	"Looks. Confidence. Health. Performance.",
	1,
	8
);

INSERT INTO rule (name, rule_category_name, rule_importance_label, description, motivation, tier, order_priority) VALUES (
	"Workout: pull",
	"Bodybuilding",
	"Absolutely essential",
	"Full bodybuilding pulling workout.",
	"Looks. Confidence. Health. Performance.",
	1,
	9
);

INSERT INTO rule (name, rule_category_name, rule_importance_label, description, motivation, tier, order_priority) VALUES (
	"Workout: legs",
	"Bodybuilding",
	"Absolutely essential",
	"Full bodybuilding leg workout.",
	"Looks. Confidence. Health. Performance.",
	1,
	10
);

INSERT INTO rule_schedule (rule_name, start_date, period, weekdays) VALUES (
	"Early rise",
	"2025-07-07", -- TODO: adjust
	1,
	127
);

-- 	"Early rise",
-- 	"Nail care",
-- 	"Home cleaning",
-- 	"Shower",
-- 	"Hair care",
-- 	"Face shave",
-- 	"Face care",
-- 	"Dental care (after sleep)",
-- 	"Fresh clothes",
-- 	"Productivity",
-- 	"Car care",
-- 	"Workout: push",
-- 	"Workout: pull",
-- 	"Workout: legs",
-- 	"Workout: cardio",
-- 	"Cooking",
-- 	"Laundry",
-- 	"Body care",
-- 	"Dental care (before sleep)",
-- 	"Homemade food",
-- 	"Diet",

-- INSERT INTO rule (name, rule_category_name, rule_importance_label, description, motivation, tier, order_priority) VALUES (
-- 	"Face care",
-- 	"Image (internal)",
-- 	"Wash and moisturize face.",
-- 	"", -- TODO: motivation,
-- 	2,
-- 	100, -- TODO: order_priority,
-- 	1 -- TODO: points
-- );
-- 
-- INSERT INTO rule (name, rule_category_name, rule_importance_label, description, motivation, tier, order_priority) VALUES (
-- 	"Dental care (before sleep)",
-- 	"Image (internal)",
-- 	"Brush teeth and wash mouth before sleep",
-- 	"", -- TODO: motivation,
-- 	2,
-- 	101, -- TODO: order_priority,
-- 	1 -- TODO: points
-- );
-- 
-- INSERT INTO rule (name, rule_category_name, rule_importance_label, description, motivation, tier, order_priority) VALUES (
-- 	"Body care",
-- 	"Image (internal)",
-- 	"Shave body. Trim nose hair if deemed necessary. Apply products if deemed necessary.",
-- 	"", -- TODO: motivation,
-- 	2,
-- 	102, -- TODO: order_priority,
-- 	1 -- TODO: points
-- );
-- 
-- INSERT INTO rule (name, rule_category_name, rule_importance_label, description, motivation, tier, order_priority) VALUES (
-- 	"Fresh clothes",
-- 	"Image (internal)",
-- 	"Dress up with a full set of fresh, clean, ironed clothes and wear perfume.",
-- 	"", -- TODO: motivation,
-- 	2,
-- 	103, -- TODO: order_priority,
-- 	1 -- TODO: points
-- );
-- 
-- INSERT INTO rule (name, rule_category_name, rule_importance_label, description, motivation, tier, order_priority) VALUES (
-- 	"Homemade food",
-- 	"Image (external)",
-- 	"Eat only homemade food throughout the day.",
-- 	"", -- TODO: motivation,
-- 	2,
-- 	104, -- TODO: order_priority,
-- 	1 -- TODO: points
-- );
-- 
-- INSERT INTO rule (name, rule_category_name, rule_importance_label, description, motivation, tier, order_priority) VALUES (
-- 	"Laundry",
-- 	"Image (external)",
-- 	"Do laundry.",
-- 	"", -- TODO: motivation,
-- 	2,
-- 	105, -- TODO: order_priority,
-- 	1 -- TODO: points
-- );
-- 
-- INSERT INTO rule (name, rule_category_name, rule_importance_label, description, motivation, tier, order_priority) VALUES (
-- 	"Car care",
-- 	"Image (external)",
-- 	"Wash car. Fuel car. Charge car battery. Take car to car shop.",
-- 	"", -- TODO: motivation,
-- 	2,
-- 	106, -- TODO: order_priority,
-- 	1 -- TODO: points
-- );
-- 
-- INSERT INTO rule (name, rule_category_name, rule_importance_label, description, motivation, tier, order_priority) VALUES (
-- 	"Cooking",
-- 	"Image (external)",
-- 	"Meal-prep for the upcoming days, weeks or even months.",
-- 	"", -- TODO: motivation,
-- 	2,
-- 	107, -- TODO: order_priority,
-- 	1 -- TODO: points
-- );
-- 
-- INSERT INTO rule (name, rule_category_name, rule_importance_label, description, motivation, tier, order_priority) VALUES (
-- 	"Productivity",
-- 	"Image (external)",
-- 	"Be productive at work.",
-- 	"", -- TODO: motivation,
-- 	2,
-- 	108, -- TODO: order_priority,
-- 	1 -- TODO: points
-- );
-- 
-- INSERT INTO rule (name, rule_category_name, rule_importance_label, description, motivation, tier, order_priority) VALUES (
-- 	"Diet",
-- 	"Bodybuilding",
-- 	"Maintain diet appropriate for current bodybuilding goals. Track bodyweight.",
-- 	"", -- TODO: motivation,
-- 	2,
-- 	109, -- TODO: order_priority,
-- 	1 -- TODO: points
-- );
-- 
-- INSERT INTO rule (name, rule_category_name, rule_importance_label, description, motivation, tier, order_priority) VALUES (
-- 	"Workout: cardio",
-- 	"Bodybuilding",
-- 	"At least an hour of zone two or more intense cardio.",
-- 	"", -- TODO: motivation,
-- 	2,
-- 	110, -- TODO: order_priority,
-- 	1 -- TODO: points
-- );
