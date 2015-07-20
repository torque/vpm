element = document.querySelector '#playbutton'
playing = true

element.addEventListener 'click', ( ev ) ->
	vpm.setProperty 'pause', if playing then 'yes' else 'no'

window.observeProperty 'pause', ( value ) ->
	playing = value is 'no'
	if playing
		element.classList.add 'playing'
	else
		element.classList.remove 'playing'
