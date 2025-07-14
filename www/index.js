const url_arguments = new URLSearchParams(window.location.search)
let specified_date = null
if (url_arguments.size == 1 && url_arguments.has("date") && url_arguments.get("date") && url_arguments.get("date").match(/^\d{4}-\d{2}-\d{2}$/) != null) {
	specified_date = url_arguments.get("date");
}

const current_date = new Date()
const current_date_string = current_date.toISOString().substring(0, 10)
specified_date = specified_date ? specified_date : current_date_string;

fetch('cgi-bin/read_day.lua', {
  method: 'POST',
  headers: { 'Content-Type': 'text/plain' },
  body: specified_date
}).then(response => response.json())
  .then(response => generate_day(response))

// TODO  5: HTML: table of tasks
// TODO  6: HTML: task_table_generation: add UP and DOWN buttons
// TODO  7: HTML: task_table_generation: add DELETE button
// TODO  9: HTML: add ADD_TASK button
// TODO 10: HTML: add ADD_TASK dropdown
// TODO 11: HTML: add button "Save"
// TODO 12: HTML: add button "Delete"
// TODO 13: HTML: add day.NOTES with payload already
// TODO 14: HTML: add navigation buttons ("Previous day", "Next day")
// TODO 15: HTML: in case of "null", button "Create Day"
// TODO 16: JS:   task_table_generatino: add UP and DOWN button empty handlers
// TODO 17: JS:   task_table_generation: add UP and DOWN button full handlers
// TODO 18: JS:   task_table_generation: add empty DELETE handler
// TODO 19: JS:   task_table_generation: add proper DELETE handler
// TODO 20: JS:   add empty navigation handlers
// TODO 21: JS:   GET index.htm
// TODO 22: JS:   add empty "Delete" handler
// TODO 23: JS:   call delete_day.lua
// TODO 24: JS:   empty "Create Day" handler
// TODO 25: JS:   call create_day.lua
// TODO 26: JS:   add empty "Save" handler
// TODO 27: JS:   save handler: convert table to console.log
// TODO 28: JS:   save handler: convert table to JSON
// TODO 29: JS:   call update_day.lua
// TODO 30: JS:   add ADD_TASK button empty handler
// TODO 31: JS:   add ADD_TASK button console handler
// TODO 32: JS:   add ADD_TASK button proper handler (attach to end of the list)
// TODO 33: JS:   save day.NOTES with payload
