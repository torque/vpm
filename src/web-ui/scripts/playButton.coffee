element = document.querySelector '#playbutton'
playing = false

element.addEventListener 'click', ( ev ) ->
	vpm.setProperty 'pause', if playing then 'yes' else 'no'

window.getInitialValueAndObserve 'pause', ( value ) ->
	playing = value is 'no'
	if playing
		element.classList.add 'playing'
	else
		element.classList.remove 'playing'
