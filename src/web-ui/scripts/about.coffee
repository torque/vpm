element = document.querySelector '#about'
display = element.style.display

window.getInitialValueAndObserve 'idle', ( value ) ->
	if value is 'no'
		element.classList.add 'gone'
	else
		element.classList.remove 'gone'
		window.setTimeout ->
			element.classList.remove 'blackout'
		, 0
