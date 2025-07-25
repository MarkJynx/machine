function add_days(date, days) {
	let result = new Date(date)
	result.setDate(result.getDate() + days)
	return result.toISOString().substring(0, 10)
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

function navigate_to_day(date, offset) {
	window.location = "?date=" + add_days(date, offset)
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
	// TODO: do not use .class
	let rows = Array.from(document.getElementById("task_table").rows).filter((r) => r.class == "rule_row") // TODO: check if exists
	return rows.reduce((x, r) => r.cells[4].innerText == name ? false : x, true)
}

function make_rule_instance_row(name, done) {
	let row = document.createElement("tr")
	// TODO: do not use .class
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

async function save_day(date) {
	let json = {"id": date, "notes": null, "rule_instances": []}
	// TODO: do not use .class
	let rows = Array.from(document.getElementById("task_table").rows).filter((r) => r.class == "rule_row") // TODO: check if exists
	json.rule_instances = rows.reduce((a, r) => { a.push(rule_row_to_dict(r, a.length, date)); return a}, [])

	let deletion = await fetch("cgi-bin/update_day.lua", {
	  method: "POST",
	  headers: { "Content-Type": "application/json" },
	  body: JSON.stringify(json)
	})
	let deletionData = await deletion.json()
}

async function delete_day(date) {
	let deletion_data = await post_date_request("delete_day", date)
	window.location.reload()
}

async function post_date_request(endpoint, date) {
	let response = await fetch("cgi-bin/" + endpoint + ".lua", {
		method: "POST",
		headers: { "Content-Type": "text/plain" },
		body: date
	})

	return await response.json()
}

async function create_day(date, rules) {
	let day = await post_date_request("create_day", date)
	generate_day(date, day, rules)
}

function generate_day(date, day, rules) {
	document.body.replaceChildren()
	if (day == null) {
		// TODO: do not copy and paste
		let navigation_table = document.createElement("table")
		let navigation_row = navigation_table.insertRow()
		make_button_cell(navigation_row, "←", function() { navigate_to_day(date, -1) })
		make_button_cell(navigation_row, "+", function() { create_day(date, rules) })
		make_button_cell(navigation_row, "→", function() { navigate_to_day(date, 1) })
		document.body.appendChild(navigation_table)
	} else {
		let task_table = document.createElement("table")
		task_table.id = "task_table"
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
}

async function main() {
	// TODO: handle errors, validate with JSON schema
	let date = get_url_date_string(window.location.search) || get_local_date_string()
	let day = await post_date_request("read_day", date)
	let rules = await post_date_request("read_rules", date)
	generate_day(date, day, rules)
}

main()
