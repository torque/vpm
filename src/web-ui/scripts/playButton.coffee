element = document.querySelector '#playbutton'
paused = false

element.addEventListener 'click', (ev) ->
	vpm.setPropertyString 'pause', if paused then 'no' else 'yes'

window.observeMpvProperty 'pause', ( value ) ->
	paused = value is 'yes'
	element.className = if paused then 'paused' else 'playing'
