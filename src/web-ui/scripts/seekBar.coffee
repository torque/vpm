seekBar = document.querySelector '#seekbar-pad'
elapsed = document.querySelector '#elapsed'

seekBar.addEventListener 'click', ( ev ) ->
	seekBox  = seekBar.getBoundingClientRect( )
	percent = Math.round( ev.clientX / seekBox.width * 100 )
	vpm.command [ "seek", String(percent), "absolute-percent", "keyframes" ]

setInterval ->
	position = vpm.getPropertyString 'percent-pos'
	return if position is undefined
	elapsed.style.width = position + '%'
, 200
