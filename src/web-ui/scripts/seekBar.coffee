seekBar = document.querySelector '#seekbar-pad'
elapsed = document.querySelector '#elapsed'

updateElapsed = ->
	position = vpm.getProperty 'percent-pos'
	return if position is undefined
	elapsed.style.width = position + '%'

seekBar.addEventListener 'click', ( ev ) ->
	seekBox  = seekBar.getBoundingClientRect( )
	percent = Math.round( ev.clientX / seekBox.width * 100 )
	vpm.commandAsync [ 'seek', String( percent ), 'absolute-percent', 'keyframes' ]

updateTimer = setInterval updateElapsed, 200

observePos = ( position ) ->
	elapsed.style.width = position + '%'

window.observeProperty 'pause', ( paused ) ->
	if paused is 'yes'
		clearInterval updateTimer
		updateTimer = false
		window.observeProperty 'percent-pos', observePos
	else if not updateTimer
		window.unobserveProperty 'percent-pos', observePos
		updateTimer = setInterval updateElapsed, 200
