volumeButton = document.querySelector '#volumebutton'
volumeSlider = document.querySelector '#volumesliderwrapper'
currentVolume = document.querySelector '#currentvolume'
muted = false

volumeButton.addEventListener 'click', ( ev ) ->
	vpm.setPropertyString 'mute', if muted then 'no' else 'yes'

shiftCoords = ( x ) ->
	sliderbounds = volumeSlider.getBoundingClientRect( )
	x - sliderbounds.left

volumeSlider.addEventListener 'click', ( ev ) ->
	vpm.setPropertyString 'volume', shiftCoords ev.clientX

volumeCallback = ( value ) ->
	currentVolume.style.width = value + '%'
	value = Number value
	if value is 0
		volumeButton.className = 'button muted'
	else if value < 50
		volumeButton.className = 'button low'
	else
		volumeButton.className = 'button high'

window.observeMpvProperty 'volume', volumeCallback

window.observeMpvProperty 'mute', ( value ) ->
	muted = value is 'yes'
	if muted
		volumeButton.className = 'button muted'
		currentVolume.style.width = '0%'
	else
		volumeCallback vpm.getPropertyString 'volume'
