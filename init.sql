PRAGMA foreign_keys = ON;

-- TODO: ensure no gaps between order_priority entries
CREATE TABLE IF NOT EXISTS rule (
	name TEXT PRIMARY KEY, -- noun
	description TEXT NOT NULL UNIQUE, -- verb
	motivation TEXT NOT NULL, -- always focus on the positives only
	order_priority INTEGER NOT NULL UNIQUE CHECK(order_priority > 0)
) STRICT, WITHOUT ROWID;

-- TODO: check against time overlaps for the same rule_name
CREATE TABLE IF NOT EXISTS rule_schedule (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	rule_name TEXT NOT NULL,
	rule_tier INTEGER NOT NULL CHECK(rule_tier > 0),
	period INTEGER NOT NULL CHECK(period >= 1 AND period <= 7), -- anything less frequent is not worthy to be a rule
	weekdays INTEGER NOT NULL CHECK(weekdays >= 0 AND weekdays <= 127), -- 7-bit integer, LSB is Monday, MSB is Sunday; NULL means all weekdays
	notes TEXT,
	FOREIGN KEY (rule_name) REFERENCES rule (name)
);

CREATE TABLE IF NOT EXISTS day (
	id TEXT PRIMARY KEY CHECK(id IS date(id, "+0 days")),
	notes TEXT
) STRICT, WITHOUT ROWID;

-- TODO: ensure no gaps and uniqueness between order_priority entries for a day
-- TODO: ensure falls into a rule_schedule (FK?)
-- TODO: consider notes
-- TODO: ensure rule_schedule_id actually applies and has the same rule_name
CREATE TABLE IF NOT EXISTS rule_instance (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	rule_name TEXT NOT NULL,
	rule_schedule_id INTEGER,
	day_id TEXT NOT NULL,
	done INTEGER NOT NULL CHECK (done == 0 OR done == 1),
	order_priority INTEGER NOT NULL CHECK(order_priority > 0),
	FOREIGN KEY (rule_name) REFERENCES rule (name),
	FOREIGN KEY (rule_schedule_id) REFERENCES rule_schedule (id),
	FOREIGN KEY (day_id) REFERENCES day (id)
) STRICT;

---------------------------------------------------------------------------------------------------

-- TODO: make a precaution (REPLACE?) so one could run this script repetitively without errors

INSERT INTO rule (name, description, motivation, order_priority) VALUES (
	"Early rise",
	"Rise from bed at 09:00 or earlier",
	"Ability to take a thorough and laid-back approach to morning chores."          || char(10) ||
	"Ability to relax and focus on oneself before diving into the day."             || char(10) ||
	"Margin for error in case of unexpected events."                                || char(10) ||
	"More useful time available during the day."                                    || char(10) ||
	"Good external image and work ethic.",
	1
);

INSERT INTO rule (name, description, motivation, order_priority) VALUES (
	"Nail care",
	"Check and clip and file fingernails and toenails.",
	"Looks. Style. Discipline & order.",
	2
);

INSERT INTO rule (name, description, motivation, order_priority) VALUES (
	"Home cleaning",
	"Clean home until results or effort spent is satisfactory.",
	"Mood. Productivity. Image.",
	3
);

INSERT INTO rule (name, description, motivation, order_priority) VALUES (
	"Shower",
	"Shower",
	"Feeling fresh and clean.",
	4
);

INSERT INTO rule (name, description, motivation, order_priority) VALUES (
	"Hair care",
	"Wash hair. Visit barber if deemed necessary. Apply products if deemed necessary.",
	"Looks. Style. Discipline & order.",
	5
);

INSERT INTO rule (name, description, motivation, order_priority) VALUES (
	"Face shave",
	"Cleanly shave facial hair.",
	"Looks. Style. Discipline & order.",
	6
);

-- INSERT INTO rule (name, description, motivation, tier, order_priority) VALUES (
-- 	"Face care",
-- 	"Wash and moisturize face.",
-- 	"Clear, healthy face skin.",
-- 	7
-- );

INSERT INTO rule (name, description, motivation, order_priority) VALUES (
	"Dental care (after sleep)",
	"Brush teeth and wash mouth after sleep",
	"Looks. Smell. Health. Money.",
	8
);

-- INSERT INTO rule (name, description, motivation, tier, order_priority) VALUES (
-- 	"Fresh clothes",
-- 	"Dress up with a full set of fresh, clean, ironed clothes and wear perfume.",
-- 	"Looks. Freshness. Confidence. Image.",
-- 	9
-- );

-- INSERT INTO rule (name, description, motivation, tier, order_priority) VALUES (
-- 	"Productivity",
-- 	"Be productive at work.",
-- 	"Security. Discipline. Competence.",
-- 	10
-- );

-- INSERT INTO rule (name, description, motivation, tier, order_priority) VALUES (
-- 	"Car care",
-- 	"Wash car. Fuel car. Charge car battery. Take car to car shop.",
-- 	"Clean, orderly vehicle. Image.",
-- 	11
-- );

INSERT INTO rule (name, description, motivation, order_priority) VALUES (
	"Workout: push (A)",
	"Full bodybuilding pushing workout (part 1/2).",
	"Looks. Confidence. Health. Performance.",
	12
);

INSERT INTO rule (name, description, motivation, order_priority) VALUES (
	"Workout: push (B)",
	"Full bodybuilding pushing workout (part 2/2).",
	"Looks. Confidence. Health. Performance.",
	13
);

INSERT INTO rule (name, description, motivation, order_priority) VALUES (
	"Workout: pull (A)",
	"Full bodybuilding pulling workout (part 1/2).",
	"Looks. Confidence. Health. Performance.",
	14
);

INSERT INTO rule (name, description, motivation, order_priority) VALUES (
	"Workout: pull (B)",
	"Full bodybuilding pulling workout (part 2/2).",
	"Looks. Confidence. Health. Performance.",
	15
);

INSERT INTO rule (name, description, motivation, order_priority) VALUES (
	"Workout: legs (A)",
	"Full bodybuilding leg workout (part 1/2).",
	"Looks. Confidence. Health. Performance.",
	16
);

INSERT INTO rule (name, description, motivation, order_priority) VALUES (
	"Workout: legs (B)",
	"Full bodybuilding leg workout (part 2/2).",
	"Looks. Confidence. Health. Performance.",
	17
);

-- INSERT INTO rule (name, description, motivation, order_priority) VALUES (
-- 	"Workout: core",
-- 	"Full bodybuilding core workout.",
-- 	"Looks. Confidence. Health. Performance.",
-- 	18
-- );

-- INSERT INTO rule (name, description, motivation, order_priority) VALUES (
-- 	"Workout: cardio",
-- 	"At least an hour of zone two or more intense cardio.",
-- 	"Confidence. Health. Endurance.",
-- 	19
-- );

-- INSERT INTO rule (name, description, motivation, order_priority) VALUES (
-- 	"Cooking",
-- 	"Image (external)",
-- 	"Meal-prep for the upcoming days, weeks or even months.",
-- 	"Facilitating homemade food and diet. Independence. Money. Image. Experimentation. Discovery.",
-- 	20
-- );

-- INSERT INTO rule (name, description, motivation, order_priority) VALUES (
-- 	"Laundry",
-- 	"Image (external)",
-- 	"Do laundry.",
-- 	"Facilitating fresh clothes. Independence. Image.",
-- 	21
-- );

-- INSERT INTO rule (name, description, motivation, order_priority) VALUES (
-- 	"Body care",
-- 	"Shave body. Trim nose hair. Apply products.",
-- 	"Looks. Sex. Image.",
-- 	22
-- );

-- INSERT INTO rule (name, description, motivation, order_priority) VALUES (
-- 	"Dental care (before sleep)",
-- 	"Brush teeth and wash mouth before sleep",
-- 	"Looks. Smell. Health. Money.",
-- 	23
-- );

-- INSERT INTO rule (name, description, motivation, order_priority) VALUES (
-- 	"Homemade food",
-- 	"Eat only homemade food throughout the day.",
-- 	"Health. Image. Diet. Control.",
-- 	24
-- );

-- TODO: probably should be merged with homemade food
-- INSERT INTO rule (name, description, motivation, order_priority) VALUES (
-- 	"Diet",
-- 	"Maintain diet appropriate for current bodybuilding goals. Track bodyweight.",
-- 	"Achieve bodybuilding goals.",
-- 	25
-- );

INSERT INTO rule_schedule (rule_name, rule_tier, period, weekdays) VALUES ("Hair care",                 1, 1, 127);

INSERT INTO rule_schedule (rule_name, rule_tier, period, weekdays) VALUES ("Early rise",                1, 1, 127);
INSERT INTO rule_schedule (rule_name, rule_tier, period, weekdays) VALUES ("Home cleaning",             1, 1, 127);
INSERT INTO rule_schedule (rule_name, rule_tier, period, weekdays) VALUES ("Dental care (after sleep)", 1, 1, 127);
INSERT INTO rule_schedule (rule_name, rule_tier, period, weekdays) VALUES ("Shower",                    1, 4, 127);
INSERT INTO rule_schedule (rule_name, rule_tier, period, weekdays) VALUES ("Hair care",                 1, 2, 127);
INSERT INTO rule_schedule (rule_name, rule_tier, period, weekdays) VALUES ("Face shave",                1, 2, 127);
INSERT INTO rule_schedule (rule_name, rule_tier, period, weekdays) VALUES ("Nail care",                 1, 7, 127);
INSERT INTO rule_schedule (rule_name, rule_tier, period, weekdays) VALUES ("Workout: push (A)",         1, 7, 127);
INSERT INTO rule_schedule (rule_name, rule_tier, period, weekdays) VALUES ("Workout: pull (A)",         1, 7, 127);
INSERT INTO rule_schedule (rule_name, rule_tier, period, weekdays) VALUES ("Workout: legs (A)",         1, 7, 127);
INSERT INTO rule_schedule (rule_name, rule_tier, period, weekdays) VALUES ("Workout: push (B)",         2, 7, 127);
INSERT INTO rule_schedule (rule_name, rule_tier, period, weekdays) VALUES ("Workout: pull (B)",         2, 7, 127);
INSERT INTO rule_schedule (rule_name, rule_tier, period, weekdays) VALUES ("Workout: legs (B)",         2, 7, 127);
