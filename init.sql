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

-- TODO: check against time overlaps for the same rule_name
CREATE TABLE IF NOT EXISTS rule_schedule (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	rule_name TEXT NOT NULL,
	start_date TEXT NOT NULL CHECK(start_date IS date(start_date, "+0 days")), -- ISO-8601, YYYY-MM-DD
	end_date TEXT CHECK(end_date IS date(end_date, "+0 days")), -- ISO-8601, YYYY-MM-DD
	period INTEGER NOT NULL CHECK(period >= 1 AND period <= 7), -- anything less frequent is not worthy to be a rule
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
	id TEXT PRIMARY KEY CHECK(id IS date(id, "+0 days")),
	notes TEXT
) WITHOUT ROWID;

-- TODO: ensure no gaps and uniqueness between order_priority entries for a day
-- TODO: ensure falls into a rule_schedule (FK?)
-- TODO: consider notes
CREATE TABLE IF NOT EXISTS rule_instance (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	rule_name TEXT NOT NULL,
	day_id TEXT NOT NULL,
	done INTEGER NOT NULL CHECK (done == 0 OR done == 1),
	order_priority INTEGER NOT NULL CHECK(order_priority > 0),
	FOREIGN KEY (rule_name) REFERENCES rule (name),
	FOREIGN KEY (day_id) REFERENCES day (id)
);

---------------------------------------------------------------------------------------------------

-- TODO: make a precaution (REPLACE?) so one could run this script repetitively without errors

-- Five value Likert scale enumeration in regards to importance
INSERT INTO rule_importance (label, value) VALUES ( "Absolutely essential", 16);
INSERT INTO rule_importance (label, value) VALUES ( "Extremely important",   8);
INSERT INTO rule_importance (label, value) VALUES ( "Very important",        4);
INSERT INTO rule_importance (label, value) VALUES ( "Important",             2);
INSERT INTO rule_importance (label, value) VALUES ( "Slightly important",    1);

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
	"Looks. Confidence. Health. Performance. Endurance.",
	0xFF0000
);

INSERT INTO rule (name, rule_category_name, rule_importance_label, description, motivation, tier, order_priority) VALUES (
	"Early rise",
	"Image (internal)",
	"Extremely important",
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
	"Nail care",
	"Image (internal)",
	"Important",
	"Check and clip and file fingernails and toenails.",
	"Looks. Style. Discipline & order.",
	1,
	2
);

INSERT INTO rule (name, rule_category_name, rule_importance_label, description, motivation, tier, order_priority) VALUES (
	"Home cleaning",
	"Image (external)",
	"Very important",
	"Clean home until results or effort spent is satisfactory.",
	"Mood. Productivity. Image.",
	1,
	3
);

INSERT INTO rule (name, rule_category_name, rule_importance_label, description, motivation, tier, order_priority) VALUES (
	"Shower",
	"Image (internal)",
	"Extremely important",
	"Shower",
	"Feeling fresh and clean.",
	1,
	4
);

INSERT INTO rule (name, rule_category_name, rule_importance_label, description, motivation, tier, order_priority) VALUES (
	"Hair care",
	"Image (internal)",
	"Very important",
	"Wash hair. Visit barber if deemed necessary. Apply products if deemed necessary.",
	"Looks. Style. Discipline & order.",
	1,
	5
);

INSERT INTO rule (name, rule_category_name, rule_importance_label, description, motivation, tier, order_priority) VALUES (
	"Face shave",
	"Image (internal)",
	"Very important",
	"Cleanly shave facial hair.",
	"Looks. Style. Discipline & order.",
	1,
	6
);

INSERT INTO rule (name, rule_category_name, rule_importance_label, description, motivation, tier, order_priority) VALUES (
	"Face care",
	"Image (internal)",
	"Important",
	"Wash and moisturize face.",
	"Clear, healthy face skin.",
	2,
	7
);

INSERT INTO rule (name, rule_category_name, rule_importance_label, description, motivation, tier, order_priority) VALUES (
	"Dental care (after sleep)",
	"Image (internal)",
	"Important",
	"Brush teeth and wash mouth after sleep",
	"Looks. Smell. Health. Money.",
	1,
	8
);

INSERT INTO rule (name, rule_category_name, rule_importance_label, description, motivation, tier, order_priority) VALUES (
	"Fresh clothes",
	"Image (internal)",
	"Very important",
	"Dress up with a full set of fresh, clean, ironed clothes and wear perfume.",
	"Looks. Freshness. Confidence. Image.",
	2,
	9
);

INSERT INTO rule (name, rule_category_name, rule_importance_label, description, motivation, tier, order_priority) VALUES (
	"Productivity",
	"Image (external)",
	"Slightly important",
	"Be productive at work.",
	"Security. Discipline. Competence.",
	2,
	10
);

INSERT INTO rule (name, rule_category_name, rule_importance_label, description, motivation, tier, order_priority) VALUES (
	"Car care",
	"Image (external)",
	"Slightly important",
	"Wash car. Fuel car. Charge car battery. Take car to car shop.",
	"Clean, orderly vehicle. Image.",
	2,
	11
);

INSERT INTO rule (name, rule_category_name, rule_importance_label, description, motivation, tier, order_priority) VALUES (
	"Workout: push",
	"Bodybuilding",
	"Absolutely essential",
	"Full bodybuilding pushing workout.",
	"Looks. Confidence. Health. Performance.",
	1,
	12
);

INSERT INTO rule (name, rule_category_name, rule_importance_label, description, motivation, tier, order_priority) VALUES (
	"Workout: pull",
	"Bodybuilding",
	"Absolutely essential",
	"Full bodybuilding pulling workout.",
	"Looks. Confidence. Health. Performance.",
	1,
	13
);

INSERT INTO rule (name, rule_category_name, rule_importance_label, description, motivation, tier, order_priority) VALUES (
	"Workout: legs",
	"Bodybuilding",
	"Absolutely essential",
	"Full bodybuilding leg workout.",
	"Looks. Confidence. Health. Performance.",
	1,
	14
);

INSERT INTO rule (name, rule_category_name, rule_importance_label, description, motivation, tier, order_priority) VALUES (
	"Workout: cardio",
	"Bodybuilding",
	"Extremely important",
	"At least an hour of zone two or more intense cardio.",
	"Confidence. Health. Endurance.",
	2,
	15
);

INSERT INTO rule (name, rule_category_name, rule_importance_label, description, motivation, tier, order_priority) VALUES (
	"Cooking",
	"Image (external)",
	"Important",
	"Meal-prep for the upcoming days, weeks or even months.",
	"Facilitating homemade food and diet. Independence. Money. Image. Experimentation. Discovery.",
	2,
	16
);

-- TODO: perhaps should be merged with fresh clothes; one cannot exist without the other.
INSERT INTO rule (name, rule_category_name, rule_importance_label, description, motivation, tier, order_priority) VALUES (
	"Laundry",
	"Image (external)",
	"Important",
	"Do laundry.",
	"Facilitating fresh clothes. Independence. Image.",
	2,
	17
);

INSERT INTO rule (name, rule_category_name, rule_importance_label, description, motivation, tier, order_priority) VALUES (
	"Body care",
	"Image (internal)",
	"Slightly important",
	"Shave body. Trim nose hair. Apply products.",
	"Looks. Sex. Image.",
	2,
	18
);

INSERT INTO rule (name, rule_category_name, rule_importance_label, description, motivation, tier, order_priority) VALUES (
	"Dental care (before sleep)",
	"Image (internal)",
	"Important",
	"Brush teeth and wash mouth before sleep",
	"Looks. Smell. Health. Money.",
	2,
	19
);

-- TODO: perhaps should be merged with cooking; one cannot exist without the other.
INSERT INTO rule (name, rule_category_name, rule_importance_label, description, motivation, tier, order_priority) VALUES (
	"Homemade food",
	"Image (external)",
	"Very important",
	"Eat only homemade food throughout the day.",
	"Health. Image. Diet. Control.",
	2,
	20
);

INSERT INTO rule (name, rule_category_name, rule_importance_label, description, motivation, tier, order_priority) VALUES (
	"Diet",
	"Bodybuilding",
	"Extremely important",
	"Maintain diet appropriate for current bodybuilding goals. Track bodyweight.",
	"Achieve bodybuilding goals.",
	2,
	21
);

INSERT INTO rule_schedule ( rule_name, start_date, end_date, period, weekdays) VALUES ( "Early rise",                "2025-07-14", NULL, 1, 127);
INSERT INTO rule_schedule ( rule_name, start_date, end_date, period, weekdays) VALUES ( "Home cleaning",             "2025-07-14", NULL, 1, 127);
INSERT INTO rule_schedule ( rule_name, start_date, end_date, period, weekdays) VALUES ( "Shower",                    "2025-07-14", NULL, 2, 127);
INSERT INTO rule_schedule ( rule_name, start_date, end_date, period, weekdays) VALUES ( "Hair care",                 "2025-07-14", NULL, 1, 127);
INSERT INTO rule_schedule ( rule_name, start_date, end_date, period, weekdays) VALUES ( "Face shave",                "2025-07-14", NULL, 1, 127);
INSERT INTO rule_schedule ( rule_name, start_date, end_date, period, weekdays) VALUES ( "Dental care (after sleep)", "2025-07-14", NULL, 1, 127);
INSERT INTO rule_schedule ( rule_name, start_date, end_date, period, weekdays) VALUES ( "Nail care",                 "2025-07-18", NULL, 7, 127);
INSERT INTO rule_schedule ( rule_name, start_date, end_date, period, weekdays) VALUES ( "Workout: pull",             "2025-07-18", NULL, 7, 127);
INSERT INTO rule_schedule ( rule_name, start_date, end_date, period, weekdays) VALUES ( "Workout: push",             "2025-07-19", NULL, 7, 127);
INSERT INTO rule_schedule ( rule_name, start_date, end_date, period, weekdays) VALUES ( "Workout: legs",             "2025-07-20", NULL, 7, 127);

---------------------------------------------------------------------------------------------------

INSERT INTO day (id) VALUES ("2025-07-14");
INSERT INTO rule_instance ( rule_name, day_id, done, order_priority) VALUES ( "Early rise",                "2025-07-14", 1, 1);
INSERT INTO rule_instance ( rule_name, day_id, done, order_priority) VALUES ( "Home cleaning",             "2025-07-14", 1, 2);
INSERT INTO rule_instance ( rule_name, day_id, done, order_priority) VALUES ( "Dental care (after sleep)", "2025-07-14", 1, 3);
INSERT INTO rule_instance ( rule_name, day_id, done, order_priority) VALUES ( "Shower",                    "2025-07-14", 1, 4);
INSERT INTO rule_instance ( rule_name, day_id, done, order_priority) VALUES ( "Hair care",                 "2025-07-14", 1, 5);
INSERT INTO rule_instance ( rule_name, day_id, done, order_priority) VALUES ( "Face shave",                "2025-07-14", 1, 6);

INSERT INTO day (id) VALUES ("2025-07-15");
INSERT INTO rule_instance ( rule_name, day_id, done, order_priority) VALUES ( "Early rise",                "2025-07-15", 1, 1);
INSERT INTO rule_instance ( rule_name, day_id, done, order_priority) VALUES ( "Home cleaning",             "2025-07-15", 1, 2);
INSERT INTO rule_instance ( rule_name, day_id, done, order_priority) VALUES ( "Dental care (after sleep)", "2025-07-15", 1, 3);
INSERT INTO rule_instance ( rule_name, day_id, done, order_priority) VALUES ( "Shower",                    "2025-07-15", 1, 4);
INSERT INTO rule_instance ( rule_name, day_id, done, order_priority) VALUES ( "Hair care",                 "2025-07-15", 1, 5);
INSERT INTO rule_instance ( rule_name, day_id, done, order_priority) VALUES ( "Face shave",                "2025-07-15", 1, 6);

INSERT INTO day (id) VALUES ("2025-07-16");
INSERT INTO rule_instance ( rule_name, day_id, done, order_priority) VALUES ( "Early rise",                "2025-07-16", 1, 1);
INSERT INTO rule_instance ( rule_name, day_id, done, order_priority) VALUES ( "Home cleaning",             "2025-07-16", 1, 2);
INSERT INTO rule_instance ( rule_name, day_id, done, order_priority) VALUES ( "Hair care",                 "2025-07-16", 0, 3);
INSERT INTO rule_instance ( rule_name, day_id, done, order_priority) VALUES ( "Dental care (after sleep)", "2025-07-16", 1, 4);
INSERT INTO rule_instance ( rule_name, day_id, done, order_priority) VALUES ( "Face shave",                "2025-07-16", 1, 5);

INSERT INTO day (id) VALUES ("2025-07-17");
INSERT INTO rule_instance ( rule_name, day_id, done, order_priority) VALUES ( "Early rise",                "2025-07-17", 1, 1);
INSERT INTO rule_instance ( rule_name, day_id, done, order_priority) VALUES ( "Home cleaning",             "2025-07-17", 1, 2);
INSERT INTO rule_instance ( rule_name, day_id, done, order_priority) VALUES ( "Dental care (after sleep)", "2025-07-17", 0, 3);
INSERT INTO rule_instance ( rule_name, day_id, done, order_priority) VALUES ( "Shower",                    "2025-07-17", 0, 4);
INSERT INTO rule_instance ( rule_name, day_id, done, order_priority) VALUES ( "Hair care",                 "2025-07-17", 0, 5);
INSERT INTO rule_instance ( rule_name, day_id, done, order_priority) VALUES ( "Face shave",                "2025-07-17", 0, 6);

INSERT INTO day (id) VALUES ("2025-07-18");
INSERT INTO rule_instance ( rule_name, day_id, done, order_priority) VALUES ( "Early rise",                "2025-07-18", 0, 1);
INSERT INTO rule_instance ( rule_name, day_id, done, order_priority) VALUES ( "Home cleaning",             "2025-07-18", 1, 2);
INSERT INTO rule_instance ( rule_name, day_id, done, order_priority) VALUES ( "Dental care (after sleep)", "2025-07-18", 1, 3);
INSERT INTO rule_instance ( rule_name, day_id, done, order_priority) VALUES ( "Shower",                    "2025-07-18", 1, 4);
INSERT INTO rule_instance ( rule_name, day_id, done, order_priority) VALUES ( "Hair care",                 "2025-07-18", 1, 5);
INSERT INTO rule_instance ( rule_name, day_id, done, order_priority) VALUES ( "Face shave",                "2025-07-18", 1, 6);
INSERT INTO rule_instance ( rule_name, day_id, done, order_priority) VALUES ( "Nail care",                 "2025-07-18", 1, 8);
INSERT INTO rule_instance ( rule_name, day_id, done, order_priority) VALUES ( "Workout: push",             "2025-07-18", 1, 9);
