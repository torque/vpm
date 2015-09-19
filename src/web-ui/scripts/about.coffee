element = document.querySelector '#about'
display = element.style.display

window.observeProperty 'idle', ( value ) ->
	if value is 'no'
		element.style.display = 'none'
	else
		element.style.display = display

