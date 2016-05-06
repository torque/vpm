volumeWidget = document.querySelector '#volumewidget'
volumeButton = document.querySelector '#volumebutton'
volumeSlider = document.querySelector '#volumesliderwrapper'
currentVolume = document.querySelector '#currentvolume'
muted = false

volumeButton.addEventListener 'click', ( ev ) ->
	vpm.setProperty 'mute', if muted then 'no' else 'yes'

shiftCoords = ( x ) ->
	sliderbounds = volumeSlider.getBoundingClientRect( )
	Math.min x - sliderbounds.left, 100

volumeSlider.addEventListener 'click', ( ev ) ->
	vpm.setProperty 'volume', shiftCoords ev.clientX

updateVolumeDisplay = ( value ) ->
	currentVolume.style.width = value + '%'
	value = Number value
	if value is 0
		volumeButton.className = 'button muted'
	else if value < 50
		volumeButton.className = 'button low'
	else
		volumeButton.className = 'button high'

window.getInitialValueAndObserve 'aid', ( value ) ->
	if value is 'no'
		volumeWidget.className = 'noaudio'
	else
		volumeWidget.className = ''

window.getInitialValueAndObserve 'volume', updateVolumeDisplay

window.getInitialValueAndObserve 'mute', ( value ) ->
	muted = value is 'yes'
	if muted
		volumeButton.className = 'button muted'
		currentVolume.style.width = '0%'
	else
		updateVolumeDisplay vpm.getProperty 'volume'
