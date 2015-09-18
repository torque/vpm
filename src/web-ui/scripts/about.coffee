element = document.querySelector '#about'
display = element.style.display

window.observeProperty 'idle', ( value ) ->
	if value is 'no'
		# aboutHidden = yes
		element.style.display = 'none'
		# console.log 'hiding about.'
	else
		element.style.display = display

