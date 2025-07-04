CREATE TABLE IF NOT EXISTS category (
	id INTEGER PRIMARY KEY AUTOINCREMENT,
	name TEXT NOT NULL UNIQUE,
	description TEXT NOT NULL UNIQUE,
	motivation TEXT NOT NULL UNIQUE,
	color INTEGER NOT NULL UNIQUE
);

INSERT INTO category (name, description, motivation, color) VALUES (
	"Image",
	"One's immediate appearance, behavior and surroundings",
	"Feeling well about one's appearance."                     || char(10) ||
	"Feeling well about how others perceive one's appearance." || char(10) ||
	"Feeling well about one's behavior."                       || char(10) ||
	"Feeling well about how others perceive one's behavior."   || char(10) ||
	"Feeling well about one's surroundings."                   || char(10) ||
	"Feeling well about how others perceive one's surroundings.",
	0x0000FF
);
