function generate_day(day) {
	document.body.replaceChildren()
	if (day == null) {
		document.body.textContent = "null"
	} else {
		document.body.textContent = "not null"
	}
}
