seekBar = document.querySelector '#seekbar-pad'
elapsed = document.querySelector '#elapsed'

seekBar.addEventListener 'click', ( ev ) ->
	seekBox  = seekBar.getBoundingClientRect( )
	percent = Math.round( ev.clientX / seekBox.width * 100 )
	vpm.commandAsync [ 'seek', String( percent ), 'absolute-percent', 'keyframes' ]

window.observeMpvProperty 'percent-pos', ( position ) ->
	return if position is undefined
	elapsed.style.width = position + '%'
