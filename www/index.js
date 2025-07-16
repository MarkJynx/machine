function add_days(date, days) {
	let result = new Date(date)
	result.setDate(result.getDate() + days)
	return result
}

function navigate_to_day(offset) {
	// TODO: declare specified_date in main() and pass it through there
	let target_date_string = add_days(specified_date, offset).toISOString().substring(0, 10)
	window.location = "?date=" + target_date_string
}

function move_up(e) {
	let row = e.target.parentNode.parentNode
	let previous = row.previousElementSibling
	let tbody = row.parentNode
	if (previous) {
		tbody.insertBefore(row, previous)
	}
}

function move_down(e) {
	let row = e.target.parentNode.parentNode
	let next = row.nextElementSibling
	let tbody = row.parentNode
	if (next) {
		tbody.insertBefore(next, row)
	}
}

function delete_me(e) {
	e.target.parentNode.parentNode.remove()
}

function rule_name_is_unique(name) {
	let table = document.getElementById("task_table")
	for (let i = 0; table && i < table.rows.length; i++) {
		let row = table.rows[i]
		if (row.class != "rule_row") {
			continue;
		}
		let rule_name = row.cells[4].innerText // TODO: validate against rules; check if exists
		console.log("checking " + rule_name + " against " + name)
		if (rule_name == name) {
			return false
		}
	}
	return true
}

function insert_task(e) {
	let creation_row = e.target.parentNode.parentNode
	let rule_name = creation_row.cells[4].firstChild.value // TODO: check if exists
	if (!rule_name_is_unique(rule_name)) {
		return
	}

	// TODO: make this into a function
	let row = document.createElement("tr")
	row.class = "rule_row"
	make_button_cell(row, "⨯", delete_me)
	make_button_cell(row, "↑", move_up)
	make_button_cell(row, "↓", move_down)
	let cell = row.insertCell()
	let checkbox = document.createElement("input")
	checkbox.type = "checkbox"
	cell.appendChild(checkbox)
	cell = row.insertCell()
	cell.innerText = rule_name

	let tbody = creation_row.parentNode
	tbody.insertBefore(row, creation_row)
}

function make_button_cell(row, txt, fn) {
	let cell = row.insertCell()
	let button = document.createElement("input")
	button.type = "button"
	button.value = txt
	button.onclick = fn
	cell.appendChild(button)
}

async function save_day() {
	let json = {"id": specified_date, "notes": null, "rule_instances": []}

	let table = document.getElementById("task_table") // TODO: check if exists
	for (let i = 0; i < table.rows.length; i++) {
		let row = table.rows[i]
		if (row.class != "rule_row") {
			continue;
		}

		let rule_name = row.cells[4].innerText // TODO: validate against rules; check if exists
		let rule_done = row.cells[3].firstChild.checked // TODO: check if exists

		json.rule_instances.push({
			"day_id": specified_date,
			"rule_name": rule_name,
			"done": Number(rule_done),
			"order_priority": json.rule_instances.length + 1
		})
	}

	let deletion = await fetch("cgi-bin/update_day.lua", {
	  method: "POST",
	  headers: { "Content-Type": "application/json" },
	  body: JSON.stringify(json)
	})
	let deletionData = await deletion.json()
}

async function delete_day() {
	let deletion = await fetch("cgi-bin/delete_day.lua", {
	  method: "POST",
	  headers: { "Content-Type": "text/plain" },
	  body: specified_date
	})
	let deletionData = await deletion.json()

	window.location.reload()
}

// Copied straight from main(), only replaced read_day.lua with create_day.lua
async function create_day() {
	let day = await fetch("cgi-bin/create_day.lua", {
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


function generate_day(day, rules) {
	document.body.replaceChildren()
	if (day == null) {
		// TODO: do not copy and paste
		let navigation_table = document.createElement("table")
		let navigation_row = navigation_table.insertRow()
		make_button_cell(navigation_row, "←", function() { navigate_to_day(-1) })
		make_button_cell(navigation_row, "+", create_day)
		make_button_cell(navigation_row, "→", function() { navigate_to_day(1) })
		document.body.appendChild(navigation_table)
	} else {
		let task_table = document.createElement("table")
		task_table.id = "task_table"
		for (i = 0; day.rule_instances != null && i < day.rule_instances.length; i++) {
			// TODO: function to make a rule instance row, that will be reuse in generate_day() and insert_task()
			let rule_name = day.rule_instances[i].rule_name
			let done = day.rule_instances[i].done

			let row = task_table.insertRow()
			row.class = "rule_row"

			make_button_cell(row, "⨯", delete_me)
			make_button_cell(row, "↑", move_up)
			make_button_cell(row, "↓", move_down)

			let cell = row.insertCell()
			let checkbox = document.createElement("input")
			checkbox.type = "checkbox"
			checkbox.checked = Boolean(done)
			cell.appendChild(checkbox)

			cell = row.insertCell()
			cell.innerText = rule_name
		}

		let row = task_table.insertRow()
		let cell = row.insertCell()

		make_button_cell(row, "↑", move_up)
		make_button_cell(row, "↓", move_down)
		make_button_cell(row, "+", insert_task)

		cell = row.insertCell()
		let selection = document.createElement("select")
		for (let i = 0; rules != null && i < rules.length; i++) {
			let option = document.createElement("option")
			option.text = rules[i].name
			selection.add(option)
		}
		cell.appendChild(selection)

		document.body.appendChild(task_table)

		let navigation_table = document.createElement("table")
		let navigation_row = navigation_table.insertRow()

		make_button_cell(navigation_row, "←", function() { navigate_to_day(-1) })
		make_button_cell(navigation_row, "⨯", delete_day)
		make_button_cell(navigation_row, "→", function() { navigate_to_day(1) })
		make_button_cell(navigation_row, "💾", save_day)

		document.body.appendChild(navigation_table)
	}
}

// TODO: turn specified_date from global to local
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
