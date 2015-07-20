element = document.querySelector '#fullscreenbutton'
fullscreen = false

element.addEventListener 'click', ( ev ) ->
	vpm.setProperty 'fullscreen', if fullscreen then "no" else "yes"

window.observeProperty 'fullscreen', ( value ) ->
	fullscreen = value isnt 'no'
	if fullscreen
		element.classList.add 'fullscreen'
	else
		element.classList.remove 'fullscreen'
