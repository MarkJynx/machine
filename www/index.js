async function main() {
	// TODO: handle errors, validate with JSON schema
	let date = get_url_date_string(window.location.search) || get_local_date_string()
	if (url_params_is_matrix(window.location.search)) {
		generate_matrix()
	} else {
		let day = await post_date_request("read_day", date)
		let rules = await post_date_request("read_rules", date)
		generate_day(date, day, rules)
	}
}

function url_params_is_matrix(url) {
	const args = new URLSearchParams(url)
	return args.size == 1 && args.has("view") && args.get("view") && args.get("view") == "matrix"
}

function get_url_date_string(url) {
	const args = new URLSearchParams(url)
	if (args.size == 1 && args.has("date") && args.get("date") && args.get("date").match(/^\d{4}-\d{2}-\d{2}$/) != null) {
		return args.get("date")
	}
	return null
}

function get_local_date_string() {
	let tzoffset = (new Date()).getTimezoneOffset() * 60000 // offset in milliseconds
	return new Date(new Date() - tzoffset).toISOString().substring(0, 10)
}

async function post_date_request(endpoint, date) {
	let response = await fetch("cgi-bin/" + endpoint + ".lua", {
		method: "POST",
		headers: { "Content-Type": "text/plain" },
		body: date
	})

	return await response.json()
}

// Matrix generation

async function generate_matrix() {
	let response = await fetch("cgi-bin/read_matrix.lua")
	let json = await response.json()
	let matrix = json.matrix

	let matrix_table = document.createElement("table")
	let header_row = matrix_table.insertRow()
	let empty_cell = header_row.insertCell()
	for (let i = 0; i < json.rules.length; i++) {
		let header_cell = header_row.insertCell()
		header_cell.innerHTML = json.rules[i].name.split(" ").join("<br>")
	}

	for (let row_index = 0; row_index < matrix.length; row_index++) {
		let current_date = add_days(json.first_day, row_index)
		let row = matrix_table.insertRow()
		let date_cell = row.insertCell()
		date_cell.innerText = current_date
		for (let col_index = 0; col_index < matrix[row_index].length; col_index++) {
			let cell = row.insertCell()
			let key = String(matrix[row_index][col_index])
			let values = { "-1": "unscheduled", "0": "not_done_not_due", "1": "done_not_due", "2": "not_done_due", "3": "done_due" }
			if (key in values) {
				cell.className = values[key]
			}
		}
	}

	document.body.appendChild(matrix_table)
}

// Day generation

function generate_day(date, day, rules) {
	document.body.replaceChildren()
	if (day == null) {
		generate_day_empty(date, rules)
	} else {
		generate_day_full(date, day, rules)
	}
}

function generate_day_empty(date, rules) {
	let navigation_table = document.createElement("table")
	let header_row = navigation_table.insertRow()
	let header_cell = header_row.insertCell()
	header_cell.colSpan = 3
	header_cell.innerText = date
	let navigation_row = navigation_table.insertRow()
	make_button_cell(navigation_row, "←", function() { navigate_to_day(date, -1) })
	make_button_cell(navigation_row, "+", function() { create_day(date, rules) })
	make_button_cell(navigation_row, "→", function() { navigate_to_day(date, 1) })
	document.body.appendChild(navigation_table)
}

function generate_day_full(date, day, rules) {
	let task_table = document.createElement("table")
	task_table.id = "task_table"

	let header_row = task_table.insertRow()
	let header_cell = header_row.insertCell()
	header_cell.colSpan = 5
	header_cell.innerText = date

	if (Array.isArray(day.rule_instances)) {
		day.rule_instances.map((i) => task_table.appendChild(make_rule_instance_row(i.rule_name, i.done)))
	}

	if (Array.isArray(rules)) {
		let row = task_table.insertRow()
		let cell = row.insertCell()
		make_button_cell(row, "↑", move_up)
		make_button_cell(row, "↓", move_down)
		make_button_cell(row, "+", insert_task)

		cell = row.insertCell()
		let selection = document.createElement("select")
		rules.map((r) => { let o = document.createElement("option"); o.text = r.name; selection.add(o) })
		cell.appendChild(selection)
	}

	document.body.appendChild(task_table)

	let navigation_table = document.createElement("table")
	let navigation_row = navigation_table.insertRow()

	make_button_cell(navigation_row, "←", function() { navigate_to_day(date, -1) })
	make_button_cell(navigation_row, "⨯", function() { delete_day(date) })
	make_button_cell(navigation_row, "→", function() { navigate_to_day(date, 1) })
	make_button_cell(navigation_row, "💾", function() { save_day(date) })

	document.body.appendChild(navigation_table)
}

function make_button_cell(row, txt, fn) {
	let cell = row.insertCell()
	let button = document.createElement("input")
	button.type = "button"
	button.value = txt
	button.onclick = fn
	cell.appendChild(button)
}

// Navigation row callbacks

async function navigate_to_day(date, offset) {
	document.body.innerHTML = ""
	let new_date = add_days(date, offset)
	let new_day = await post_date_request("read_day", new_date)
	let new_rules = await post_date_request("read_rules", new_date)
	generate_day(new_date, new_day, new_rules)
}

function add_days(date, days) {
	let result = new Date(date)
	result.setDate(result.getDate() + days)
	return result.toISOString().substring(0, 10)
}

async function create_day(date, rules) {
	let day = await post_date_request("create_day", date)
	generate_day(date, day, rules)
}

async function delete_day(date) {
	let deletion_data = await post_date_request("delete_day", date)
	generate_day(date, null, null)
}

async function save_day(date) {
	let json = {"id": date, "notes": null, "rule_instances": []}
	let rows = Array.from(document.getElementById("task_table").rows).filter((r) => r.className == "rule_row") // TODO: check if exists
	json.rule_instances = rows.reduce((a, r) => { a.push(rule_row_to_dict(r, a.length, date)); return a}, [])

	let deletion = await fetch("cgi-bin/update_day.lua", {
	  method: "POST",
	  headers: { "Content-Type": "application/json" },
	  body: JSON.stringify(json)
	})
	let deletionData = await deletion.json()
}

function rule_row_to_dict(row, index, date) {
	let name = row.cells[4].innerText // TODO: validate against rules; check if exists
	let done = row.cells[3].firstChild.checked // TODO: check if exists
	return {
		"day_id": date,
		"rule_name": name,
		"done": Number(done),
		"order_priority": index + 1
	}
}

// Task rows

function make_rule_instance_row(name, done) {
	let row = document.createElement("tr")
	row.className = "rule_row"

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

function delete_me(e) {
	e.target.parentNode.parentNode.remove()
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

// Insert task row

function insert_task(e) {
	let creation_row = e.target.parentNode.parentNode
	let rule_name = creation_row.cells[4].firstChild.value // TODO: check if exists
	if (!rule_name_is_unique(rule_name)) {
		return
	}

	let tbody = creation_row.parentNode
	tbody.insertBefore(make_rule_instance_row(rule_name, 0), creation_row)
}

function rule_name_is_unique(name) {
	let rows = Array.from(document.getElementById("task_table").rows).filter((r) => r.className == "rule_row") // TODO: check if exists
	return rows.reduce((x, r) => r.cells[4].innerText == name ? false : x, true)
}

// Run-time

main()
