const url_arguments = new URLSearchParams(window.location.search)
let specified_date = null
// TODO: better validation / error-reporting
if (url_arguments.size == 1 && url_arguments.has("date") && url_arguments.get("date") && url_arguments.get("date").match(/^\d{4}-\d{2}-\d{2}$/) != null) {
	specified_date = url_arguments.get("date")
}

const current_date = new Date()
const current_date_string = current_date.toISOString().substring(0, 10)
specified_date = specified_date ? specified_date : current_date_string

async function main() {
	// TODO: handle errors, validate with JSON schema
	let day = await fetch("cgi-bin/read_day.lua", {
	  method: "POST",
	  headers: { "Content-Type": "text/plain" },
	  body: specified_date
	})
	let dayData = await day.json()

	// TODO: handle errors, validate with JSON schema
	let rules = await fetch("cgi-bin/read_rules.lua")
	let rulesData = await rules.json()

	generate_day(dayData, rulesData)
}

main()

// TODO 1: save handler: convert table to JSON
// TODO 2: call update_day.lua
// TODO 3: add ADD_TASK button proper handler (do not allow duplicates)
