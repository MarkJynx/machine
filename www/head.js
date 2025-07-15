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
		let navigation_cell = navigation_row.insertCell()
		let navigation_button = document.createElement("input")
		navigation_button.type = "button"
		navigation_button.value = "←"
		navigation_button.onclick = function() { navigate_to_day(-1) }
		navigation_cell.appendChild(navigation_button)

		navigation_cell = navigation_row.insertCell()
		navigation_button = document.createElement("input")
		navigation_button.type = "button"
		navigation_button.value = "+"
		navigation_button.onclick = create_day
		navigation_cell.appendChild(navigation_button)

		navigation_cell = navigation_row.insertCell()
		navigation_button = document.createElement("input")
		navigation_button.type = "button"
		navigation_button.value = "→"
		navigation_button.onclick = function() { navigate_to_day(1) }
		navigation_cell.appendChild(navigation_button)

		document.body.appendChild(navigation_table)
	} else {
		let task_table = document.createElement("table")
		for (i = 0; day.rule_instances != null && i < day.rule_instances.length; i++) {
			let rule_name = day.rule_instances[i].rule_name
			let done = day.rule_instances[i].done

			let row = task_table.insertRow()
			row.id = rule_name

			let cell = row.insertCell()
			let button = document.createElement("input")
			button.type = "button"
			button.value = "❌"
			button.onclick = delete_me
			cell.appendChild(button)

			cell = row.insertCell()
			button = document.createElement("input")
			button.type = "button"
			button.value = "↑"
			button.onclick = move_up
			cell.appendChild(button)

			cell = row.insertCell()
			button = document.createElement("input")
			button.type = "button"
			button.value = "↓"
			button.onclick = move_down
			cell.appendChild(button)

			cell = row.insertCell()
			let checkbox = document.createElement("input")
			checkbox.type = "checkbox"
			checkbox.checked = Boolean(done)
			cell.appendChild(checkbox)

			cell = row.insertCell()
			cell.innerText = rule_name
		}

		let row = task_table.insertRow()
		let cell = row.insertCell()

		cell = row.insertCell()
		let button = document.createElement("input")
		button.type = "button"
		button.value = "↑"
		button.onclick = move_up
		cell.appendChild(button)

		cell = row.insertCell()
		button = document.createElement("input")
		button.type = "button"
		button.value = "↓"
		button.onclick = move_down
		cell.appendChild(button)

		cell = row.insertCell()
		button = document.createElement("input")
		button.type = "button"
		button.value = "+"
		cell.appendChild(button)

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
		let navigation_cell = navigation_row.insertCell()
		let navigation_button = document.createElement("input")
		navigation_button.type = "button"
		navigation_button.value = "←"
		navigation_button.onclick = function() { navigate_to_day(-1) }
		navigation_cell.appendChild(navigation_button)

		navigation_cell = navigation_row.insertCell()
		navigation_button = document.createElement("input")
		navigation_button.type = "button"
		navigation_button.value = "❌"
		navigation_button.onclick = delete_day
		navigation_cell.appendChild(navigation_button)

		navigation_cell = navigation_row.insertCell()
		navigation_button = document.createElement("input")
		navigation_button.type = "button"
		navigation_button.value = "→"
		navigation_button.onclick = function() { navigate_to_day(1) }
		navigation_cell.appendChild(navigation_button)

		navigation_cell = navigation_row.insertCell()
		navigation_button = document.createElement("input")
		navigation_button.type = "button"
		navigation_button.value = "💾"
		navigation_cell.appendChild(navigation_button)

		document.body.appendChild(navigation_table)
	}
}
