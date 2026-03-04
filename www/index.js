async function main() {
	let args = parse_url_params(window.location.search)
	if (args.view != "day") {
		generate_matrix(args.view == "weekmatrix", args.start_date, args.stop_date)
	} else {
		let json = await post_date_request("read_day", args.date)
		generate_day(args.date, json.day, json.rules)
	}
}

function parse_url_params(url) {
	let results = {"view": "day", "date": get_local_date_string(), "start_date": null, "stop_date": null}
	const args = new URLSearchParams(url)

	if (args.has("view") && (args.get("view") == "matrix" || args.get("view") == "weekmatrix")) {
		results.view = args.get("view")
	}

	["date", "start_date", "stop_date"].forEach(function(value, index) {
		if (args.has(value) && args.get(value) && args.get(value).match(/^\d{4}-\d{2}-\d{2}$/) != null) {
			results[value] = args.get(value)
		}
	})

	return results
}

function get_local_date_string() {
	let tzoffset = (new Date()).getTimezoneOffset() * 60000 // offset in milliseconds
	return new Date(new Date() - tzoffset).toISOString().substring(0, 10) // TODO: do not use magic numbers
}

async function post_date_request(endpoint, date) {
	let response = await fetch("cgi-bin/" + endpoint + ".lua", {
		method: "POST",
		headers: { "Content-Type": "text/plain" },
		body: date
	})

	return await response.json()
}

function add_days(date, days) {
	let result = new Date(date)
	result.setDate(result.getDate() + days)
	return result.toISOString().substring(0, 10)  // TODO: do not use magic numbers
}

// Matrix generation

async function generate_matrix(week_view, start_date=null, stop_date=null) {
	let response = await fetch("cgi-bin/read_matrix.lua")
	let json = await response.json()
	let matrix = week_view ? json.week_matrix : json.matrix
	let labels = week_view ? json.week_matrix_labels : json.matrix_labels

	generate_matrix_rule_filter(json.rules)

	let matrix_table = document.createElement("table")
	let header_row = matrix_table.insertRow()

	// Header
	header_row.insertCell() // empty cell
	json.rules.forEach(function(value, index) {
		let header_cell = header_row.insertCell()
		header_cell.className = "rule" + index
		header_cell.innerHTML = json.rules[index].name.split(" ").join("<br>")
	})

	// Body
	for (let i = (start_date ? labels.indexOf(start_date) : 0); i < (stop_date ? labels.indexOf(stop_date) + 1 : matrix.length); i++) {
		let row = matrix_table.insertRow()
		let week_href = "?view=matrix&start_date=" + labels[i] + "&stop_date=" + add_days(labels[i], 6)
		make_button_cell(row, labels[i], week_view ? week_href :  "?date=" + labels[i])
		matrix[i].forEach(function(value, index) { insert_matrix_cell(row, index, value) })
	}

	let streak_row = matrix_table.insertRow()
	let total_row = matrix_table.insertRow()
	streak_row.insertCell().innerText = "Streak"
	total_row.insertCell().innerText = "%"
	json.rules.forEach(function(rule, index) {
		let col = matrix.map((row) => row[index]) // TODO: optimize, calculate all columns stats in one gow
		let current_streak = col.reduce((a, x) => [0, 1, 3].includes(x) ? a + 1 : 0, 0)
		let current_streaks = col.reduce((a, x) => { a.push([0, 1, 3].includes(x) ? (a.length > 0 ? a[a.length - 1] : 0) + 1 : 0); return a }, [])
		let longest_streak = Math.max(...current_streaks)
		let streak_cell = streak_row.insertCell()
		streak_cell.className = "rule" + index
		streak_cell.innerText = current_streak + " / " + longest_streak
		streak_cell.style.fontWeight = (current_streak == longest_streak) ? "bold" : "normal"
		total_row.insertCell().innerText = rule_array_to_percentage(col)
	})

	document.body.appendChild(matrix_table)

	let navigation_table = document.createElement("table")
	insert_navigation_row(navigation_table, null)
	document.body.appendChild(navigation_table)
}

function rule_array_to_percentage(arr) {
	// TODO: do not use magic numbers
	// TODO: configurable formulas
	let fraction = arr.reduce((a, x) => a + ([0, 1, 3].includes(x) ? 1 : 0), 0)
	let total = fraction + arr.reduce((a, x) => a + (x == 2 ? 1 : 0), 0)
	return total > 0 ? String(Math.round(fraction / total * 100)) + "%" : "N/A"
}

function generate_matrix_rule_filter(rules) {
	let rule_filter_table = document.createElement("table")
	let header_row = rule_filter_table.insertRow()
	let checkbox_row = rule_filter_table.insertRow()
	rules.forEach(function(rule, index) {
		header_row.insertCell().innerHTML = rule.name.split(" ").join("<br>")
		let checkbox = document.createElement("input")
		checkbox.type = "checkbox"
		checkbox.checked = true
		checkbox.id = "rule_filter_" + index
		checkbox.onclick = function(e) { Array.from(document.getElementsByClassName("rule" + index)).forEach(function(c) { c.hidden = !e.target.checked })}
		checkbox_row.insertCell().appendChild(checkbox)
	})
	document.body.appendChild(rule_filter_table)
}

function insert_matrix_cell(row, rule_index, c) {
	let rule_class = "rule" + rule_index
	let cell = row.insertCell()
	let values = { "-2": "no_day", "-1": "no_instance", "0": "done0due0", "1": "done1due0", "2": "done0due1", "3": "done1due1" }
	cell.className = values[String(c)] + " " + rule_class
}

// Day generation

function generate_day(date, day, rules) {
	document.body.replaceChildren()

	let task_table = document.createElement("table")
	task_table.id = "task_table"

	let header_cell = task_table.insertRow().insertCell()
	header_cell.colSpan = 5
	header_cell.innerText = date

	if (day) {
		day.rule_instances.map((i) => task_table.appendChild(make_rule_instance_row(i.rule_name, i.done)))

		let row = task_table.insertRow()
		row.insertCell()
		make_button_cell(row, "↑", function(e) { move_elem(e, 1)} )
		make_button_cell(row, "↓", function(e) { move_elem(e, 0)} )
		make_button_cell(row, "+", insert_task)

		let selection_cell = row.insertCell()
		let selection = document.createElement("select")
		rules.map((r) => { let o = document.createElement("option"); o.text = r.name; selection.add(o) }) // TODO: forEach
		selection_cell.appendChild(selection)

	}

	document.body.appendChild(task_table)

	let navigation_table = document.createElement("table")
	let navigation_row = insert_navigation_row(navigation_table, date)
	if (day) {
		make_button_cell(navigation_row, "⨯", function() { delete_day(date) })
		make_button_cell(navigation_row, "💾", function() { save_day(date) })
	} else {
		make_button_cell(navigation_row, "+", function() { create_day(date, rules) })
	}
	document.body.appendChild(navigation_table)
}

function insert_navigation_row(navigation_table, date) {
	let navigation_row = navigation_table.insertRow()
	make_button_cell(navigation_row, "7", "?view=weekmatrix")
	make_button_cell(navigation_row, "1", "?view=matrix")
	if (date != null) {
		make_button_cell(navigation_row, "←", "?date=" + add_days(date, -1))
		make_button_cell(navigation_row, "→", "?date=" + add_days(date, 1))
	}
	return navigation_row
}

function make_button_cell(row, txt, fn) {
	let cell = row.insertCell()
	let button = document.createElement("input")
	button.type = "button"
	button.value = txt
	button.onclick = typeof(fn) == "string" ? function() { window.location.href = fn } : fn
	cell.appendChild(button)
}

// Navigation row callbacks

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
	json.rule_instances = rows.reduce((a, r) => { a.push(rule_row_to_dict(r, a.length, date)); return a}, []) // TODO: map

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

	make_button_cell(row, "⨯", function(e) { e.target.parentNode.parentNode.remove() })
	make_button_cell(row, "↑", function(e) { move_elem(e, 1)})
	make_button_cell(row, "↓", function(e) { move_elem(e, 0)})

	let checkbox = document.createElement("input")
	checkbox.type = "checkbox"
	checkbox.checked = Boolean(done)
	row.insertCell().appendChild(checkbox)

	row.insertCell().innerText = name

	return row
}

function move_elem(e, up) {
	let row = e.target.parentNode.parentNode
	let other = up ? row.previousElementSibling : row.nextElementSibling
	if (other) {
		row.parentNode.insertBefore(up ? row : other, up ? other : row)
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
