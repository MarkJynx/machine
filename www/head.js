function move_up(e) {
	let row = e.target.parentNode.parentNode;
	let previous = row.previousElementSibling;
	let tbody = row.parentNode;
	if (previous) {
		tbody.insertBefore(row, previous);
	}
}

function move_down(e) {
	let row = e.target.parentNode.parentNode;
	let next = row.nextElementSibling;
	let tbody = row.parentNode;
	if (next) {
		tbody.insertBefore(next, row);
	}
}

function delete_me(e) {
	e.target.parentNode.parentNode.remove();
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
		navigation_cell.appendChild(navigation_button)

		navigation_cell = navigation_row.insertCell()
		navigation_button = document.createElement("input")
		navigation_button.type = "button"
		navigation_button.value = "+"
		navigation_cell.appendChild(navigation_button)

		navigation_cell = navigation_row.insertCell()
		navigation_button = document.createElement("input")
		navigation_button.type = "button"
		navigation_button.value = "→"
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
			button.onclick = delete_me;
			cell.appendChild(button)

			cell = row.insertCell()
			button = document.createElement("input")
			button.type = "button"
			button.value = "↑"
			button.onclick = move_up;
			cell.appendChild(button)

			cell = row.insertCell()
			button = document.createElement("input")
			button.type = "button"
			button.value = "↓"
			button.onclick = move_down;
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
		button.onclick = move_up;
		cell.appendChild(button)

		cell = row.insertCell()
		button = document.createElement("input")
		button.type = "button"
		button.value = "↓"
		button.onclick = move_down;
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
		navigation_cell.appendChild(navigation_button)

		navigation_cell = navigation_row.insertCell()
		navigation_button = document.createElement("input")
		navigation_button.type = "button"
		navigation_button.value = "❌"
		navigation_cell.appendChild(navigation_button)

		navigation_cell = navigation_row.insertCell()
		navigation_button = document.createElement("input")
		navigation_button.type = "button"
		navigation_button.value = "→"

		navigation_cell.appendChild(navigation_button)
		navigation_cell = navigation_row.insertCell()
		navigation_button = document.createElement("input")
		navigation_button.type = "button"
		navigation_button.value = "💾"
		navigation_cell.appendChild(navigation_button)

		document.body.appendChild(navigation_table)
	}
}
