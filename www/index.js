const url_arguments = new URLSearchParams(window.location.search)
let specified_date = null
// TODO: better validation / error-reporting
if (url_arguments.size == 1 && url_arguments.has("date") && url_arguments.get("date") && url_arguments.get("date").match(/^\d{4}-\d{2}-\d{2}$/) != null) {
	specified_date = url_arguments.get("date");
}

const current_date = new Date()
const current_date_string = current_date.toISOString().substring(0, 10)
specified_date = specified_date ? specified_date : current_date_string;

async function main() {
	// TODO: handle errors, validate with JSON schema
	let day = await fetch('cgi-bin/read_day.lua', {
	  method: 'POST',
	  headers: { 'Content-Type': 'text/plain' },
	  body: specified_date
	})
	let dayData = await day.json()

	// TODO: handle errors, validate with JSON schema
	let rules = await fetch('cgi-bin/read_rules.lua')
	let rulesData = await rules.json()

	generate_day(dayData, rulesData)
}

main()

// TODO  1: JS:   task_table_generatino: add UP and DOWN button empty handlers
// TODO  2: JS:   task_table_generation: add UP and DOWN button full handlers
// TODO  3: JS:   task_table_generation: add empty DELETE handler
// TODO  4: JS:   task_table_generation: add proper DELETE handler
// TODO  5: JS:   add empty navigation handlers
// TODO  6: JS:   GET index.htm
// TODO  7: JS:   add empty "Delete" handler
// TODO  8: JS:   call delete_day.lua
// TODO  9: JS:   empty "Create Day" handler
// TODO 10: JS:   call create_day.lua
// TODO 11: JS:   add empty "Save" handler
// TODO 12: JS:   save handler: convert table to console.log
// TODO 13: JS:   save handler: convert table to JSON
// TODO 14: JS:   call update_day.lua
// TODO 15: JS:   add ADD_TASK button empty handler
// TODO 16: JS:   add ADD_TASK button console handler
// TODO 17: JS:   add ADD_TASK button proper handler (attach to end of the list)
// TODO 18: JS:   save day.NOTES with payload
// TODO 19: HTML: add day.NOTES with payload already
