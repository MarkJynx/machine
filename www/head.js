function generate_day(day, rules) {
	document.body.replaceChildren()
	if (day == null) {
		document.body.textContent = "null"
	} else {
		console.log(day)
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
			cell.appendChild(button)

			cell = row.insertCell()
			button = document.createElement("input")
			button.type = "button"
			button.value = "↑"
			cell.appendChild(button)

			cell = row.insertCell()
			button = document.createElement("input")
			button.type = "button"
			button.value = "↓"
			cell.appendChild(button)

			cell = row.insertCell()
			let checkbox = document.createElement("input")
			checkbox.type = "checkbox"
			checkbox.checked = Boolean(done)
			cell.appendChild(checkbox)

			cell = row.insertCell()
			cell.innerText = rule_name
			console.log(rule_name)
		}

		let row = task_table.insertRow()
		let cell = row.insertCell()
		cell = row.insertCell()
		cell = row.insertCell()
		cell = row.insertCell()
		let button = document.createElement("input")
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
	}
}
