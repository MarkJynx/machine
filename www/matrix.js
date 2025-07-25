function add_days(date, days) { // TODO: do not copy-paste from index.js
	let result = new Date(date)
	result.setDate(result.getDate() + days)
	return result.toISOString().substring(0, 10)
}

async function main() {
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
			let value = matrix[row_index][col_index]
			// TODO: refactor
			if (value < 0) {
				cell.className = "unscheduled"
			} else if (value == 0) {
				cell.className = "not_done_not_due"
			} else if (value == 1) {
				cell.className = "done_not_due"
			} else if (value == 2) {
				cell.className = "not_done_due"
			} else { // value == 3
				cell.className = "done_due"
			}
		}
	}

	document.body.appendChild(matrix_table)
}

main()
