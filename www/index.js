async function main() {
	const url_args = new URLSearchParams(window.location.search)
	let args = {"view": null, "date": get_local_date_string(), "start_date": null, "stop_date": null}

	if (url_args.has("view") && (url_args.get("view") == "matrix" || url_args.get("view") == "weekmatrix")) {
		args.view = url_args.get("view")
	}

	["date", "start_date", "stop_date"].forEach(function(value, index) {
		if (url_args.has(value) && url_args.get(value) && url_args.get(value).match(/^\d{4}-\d{2}-\d{2}$/) != null) {
			args[value] = url_args.get(value)
		}
	})

	if (args.view) {
		generate_matrix(args.view == "weekmatrix", args.start_date, args.stop_date)
	} else {
		let json = await post_date_request("read_day", args.date)
		generate_day(args.date, json.day, json.rules)
	}
}

function get_local_date_string() {
	let tzoffset = (new Date()).getTimezoneOffset() * 60000 // offset in milliseconds
	return new Date(new Date() - tzoffset).toISOString().substring(0, "YYYY-MM-DD".length)
}

function add_days(date, days) {
	let result = new Date(date)
	result.setDate(result.getDate() + days)
	return result.toISOString().substring(0, "YYYY-MM-DD".length)
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

async function generate_matrix(week_view, start_date=null, stop_date=null) {
	let response = await fetch("cgi-bin/read_matrix.lua")
	let json = await response.json()
	let matrix = week_view ? json.week_matrix : json.matrix
	let labels = week_view ? json.week_matrix_labels : json.matrix_labels

	generate_matrix_rule_filter(json.rules, matrix)

	let matrix_table = document.createElement("table")
	let header_row = matrix_table.insertRow()

	// Header
	header_row.insertCell() // empty cell
	json.rules.forEach(function(value, index) {
		let header_cell = header_row.insertCell()
		header_cell.className = "rule" + index
		header_cell.innerHTML = json.rules[index].name.split(" ").join("<br>")
	})
	header_row.insertCell().innerText = "%"

	// Body
	let start_index = start_date ? labels.indexOf(start_date) : 0
	let stop_index = stop_date ? labels.indexOf(stop_date) + 1 : labels.length
	for (let i = start_index; i < stop_index; i++) {
		let row = matrix_table.insertRow()
		let week_href = "?view=matrix&start_date=" + labels[i] + "&stop_date=" + add_days(labels[i], 6)
		make_button_cell(row, labels[i], week_view ? week_href :  "?date=" + labels[i])
		matrix[i].forEach(function(value, index) { insert_matrix_cell(row, index, value) })
		let row_total_cell = row.insertCell()
		row_total_cell.className = "row_total"
		row_total_cell.id = "row_total" + i
	}

	let streak_row = matrix_table.insertRow()
	let total_row = matrix_table.insertRow()
	streak_row.insertCell().innerText = "Streak"
	total_row.insertCell().innerText = "%"
	json.rules.forEach(function(rule, index) {
		let col = matrix.map((row) => row[index]).slice(start_index, stop_index)  // TODO: handle length of zero
		let current_streaks = col.reduce((a, x) => { a.push([0, 1, 3].includes(x) ? (a.length > 0 ? a[a.length - 1] : 0) + 1 : 0); return a }, [])
		let current_streak = current_streaks[current_streaks.length - 1]
		let longest_streak = Math.max(...current_streaks)
		let streak_cell = streak_row.insertCell()
		streak_cell.className = "rule" + index
		streak_cell.innerText = current_streak + " / " + longest_streak
		streak_cell.style.fontWeight = (current_streak == longest_streak) ? "bold" : "normal"
		let total = col.reduce((a, x) => a + ([0, 1, 2, 3].includes(x) ? 1 : 0), 0)
		let count = col.reduce((a, x) => a + ([0, 1, 3].includes(x) ? 1 : 0), 0)
		let total_cell = total_row.insertCell()
		total_cell.className = "rule" + index
		total_cell.innerText = total ? Math.round(count / total * 100) + "%" : "N/A"
	})
	streak_row.insertCell().id = "streak_row_total"
	total_row.insertCell().id = "total_row_total"

	document.body.appendChild(matrix_table)
	update_day_totals(json.rules, matrix)

	let navigation_table = document.createElement("table")
	insert_navigation_row(navigation_table, null)
	document.body.appendChild(navigation_table)
}

function generate_matrix_rule_filter(rules, matrix) {
	let rule_filter_table = document.createElement("table")
	let header_row = rule_filter_table.insertRow()
	let checkbox_row = rule_filter_table.insertRow()
	rules.forEach(function(rule, index) {
		header_row.insertCell().innerHTML = rule.name.split(" ").join("<br>")
		let checkbox = document.createElement("input")
		checkbox.type = "checkbox"
		checkbox.checked = true
		checkbox.id = "rule_filter_" + index
		checkbox.onclick = function(e) {
			Array.from(document.getElementsByClassName("rule" + index)).forEach(function(c) {
				c.hidden = !e.target.checked
			})
			rules[index].hidden = !e.target.checked
			update_day_totals(rules, matrix)
		}
		checkbox_row.insertCell().appendChild(checkbox)
	})
	document.body.appendChild(rule_filter_table)
}

function update_day_totals(rules, matrix) {
	let shown_rules = Array.from(rules.filter((rule) => !rule.hidden)) // TODO: handle length of zero
	let shown_rule_indices = Array.from(shown_rules.map((rule) => rules.indexOf(rule)))
	let rows = Array.from(document.getElementsByClassName("row_total")) // TODO: handle length of zero
	let row_indices = Array.from(rows.map((cell) => parseInt(cell.id.substring(9))))
	let counts = Array.from(row_indices.map((row_index) => shown_rule_indices.reduce((a, rule_index) => a + [0, 1, 3].includes(matrix[row_index][rule_index]), 0)))
	let totals = Array.from(row_indices.map((row_index) => shown_rule_indices.reduce((a, rule_index) => a + [0, 1, 2, 3].includes(matrix[row_index][rule_index]), 0)))
	let counts_and_totals = Array.from(counts.map((count, index) => [counts[index], totals[index]]))
	let perfect_row_count = counts_and_totals.reduce((a, count_and_total) => a + (count_and_total[0] == count_and_total[1] ? 1 : 0), 0)
	let perfect_row_total = rows.length
	let current_perfect_row_streaks = counts_and_totals.reduce(function(a, ct, i) { a.push(ct[0] && ct[0] == ct[1] ? i ? a[i - 1] + 1 : 1 : 0); return a }, [])
	let longest_perfect_row_streak = Math.max(...current_perfect_row_streaks)
	let current_perfect_row_streak = current_perfect_row_streaks[current_perfect_row_streaks.length - 1]
	let make_fraction_string = (count, total, fraction) => total ? (fraction ? (count + " / " + total + "<br>") : "") + Math.round(count / total * 100) + "%" : "N/A"
	rows.forEach(function(cell, index) { cell.innerHTML = make_fraction_string(counts[index], totals[index], false) })
	document.getElementById("streak_row_total").innerText = current_perfect_row_streak + " / " + longest_perfect_row_streak
	document.getElementById("streak_row_total").style.fontWeight = (current_perfect_row_streak == longest_perfect_row_streak) ? "bold" : "normal"
	document.getElementById("total_row_total").innerHTML = make_fraction_string(perfect_row_count, perfect_row_total, true)
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
		make_button_cell(row, "↑", function(e) { move_elem(e, true)} )
		make_button_cell(row, "↓", function(e) { move_elem(e, false)} )
		make_button_cell(row, "+", insert_task)

		let selection = document.createElement("select")
		rules.forEach(function(rule, index) { let o = document.createElement("option"); o.text = rule.name; selection.add(o) })
		row.insertCell().appendChild(selection)

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
	let rows = Array.from(document.getElementsByClassName("rule_row"))
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
	return { "day_id": date, "rule_name": name, "done": Number(done), "order_priority": index + 1 }
}

// Task rows

function make_rule_instance_row(name, done) {
	let row = document.createElement("tr")
	row.className = "rule_row"

	make_button_cell(row, "⨯", function(e) { e.target.parentNode.parentNode.remove() })
	make_button_cell(row, "↑", function(e) { move_elem(e, true)})
	make_button_cell(row, "↓", function(e) { move_elem(e, false)})

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

function insert_task(e) { // TODO: no magic numbers(4)
	let creation_row = e.target.parentNode.parentNode
	let rule_name = creation_row.cells[4].firstChild.value // TODO: check if exists
	let rule_names = Array.from(Array.from(document.getElementsByClassName("rule_row")).map((row) => row.cells[4].innerText))
	if (!rule_names.includes(rule_name)) {
		let tbody = creation_row.parentNode
		tbody.insertBefore(make_rule_instance_row(rule_name, 0), creation_row)
	}
}

// Run-time

main()
