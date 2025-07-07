CREATE TABLE IF NOT EXISTS category (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	name TEXT NOT NULL UNIQUE,
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

CREATE TABLE IF NOT EXISTS task (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	name TEXT NOT NULL UNIQUE,
	description TEXT NOT NULL UNIQUE,
	motivation TEXT NOT NULL UNIQUE,
	schedule_period INTEGER NOT NULL CHECK(schedule_period >= 1 AND schedule_period < 7), -- anything less frequent is not worthy to be a rule
	schedule_weekdays INTEGER NOT NULL CHECK(schedule_weekdays >= 0 AND schedule_weekdays <= 127), -- 7-bit integer, LSB is Monday, MSB is Sunday
	tier INTEGER NOT NULL CHECK(tier > 0),
	order_priority INTEGER NOT NULL CHECK(order_priority > 0),
	points INTEGER NOT NULL CHECK(points > 0),
	color INTEGER NOT NULL CHECK(color >= 0 and color <= 0xFFFFFF)
);
