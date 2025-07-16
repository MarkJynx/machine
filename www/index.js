function add_days(date, days) {
	let result = new Date(date)
	result.setDate(result.getDate() + days)
	return result
}

function get_local_date_string() {
	let tzoffset = (new Date()).getTimezoneOffset() * 60000 // offset in milliseconds
	return new Date(new Date() - tzoffset).toISOString().substring(0, 10)
}

function get_url_date_string(url) {
	const args = new URLSearchParams(url)
	if (args.size == 1 && args.has("date") && args.get("date") && args.get("date").match(/^\d{4}-\d{2}-\d{2}$/) != null) {
		return args.get("date")
	}
	return null
}

function navigate_to_day(offset) {
	// TODO: retrieve specified_date through arguments
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
	let rows = Array.from(document.getElementById("task_table").rows)
	return rows.reduce((x, r) => r.class == "rule_row" && r.cells[4].innerText == name ? false : x, true)
}

function make_rule_instance_row(name, done) {
	let row = document.createElement("tr")
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
	cell.innerText = name

	return row
}

function insert_task(e) {
	let creation_row = e.target.parentNode.parentNode
	let rule_name = creation_row.cells[4].firstChild.value // TODO: check if exists
	if (!rule_name_is_unique(rule_name)) {
		return
	}

	let tbody = creation_row.parentNode
	tbody.insertBefore(make_rule_instance_row(rule_name, 0), creation_row)
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

	// TODO REFACTOR: REDUCE
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
		// TODO REFACTOR: REDUCE / MAP
		for (i = 0; day.rule_instances != null && i < day.rule_instances.length; i++) {
			// TODO: function to make a rule instance row, that will be reuse in generate_day() and insert_task()
			let rule_name = day.rule_instances[i].rule_name
			let done = day.rule_instances[i].done
			task_table.appendChild(make_rule_instance_row(rule_name, done))
		}

		let row = task_table.insertRow()
		let cell = row.insertCell()

		make_button_cell(row, "↑", move_up)
		make_button_cell(row, "↓", move_down)
		make_button_cell(row, "+", insert_task)

		cell = row.insertCell()
		let selection = document.createElement("select")
		// TODO REFACTOR: REDUCE / MAP
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

let specified_date = get_url_date_string(window.location.search) || get_local_date_string() // TODO: turn to local
main()
