seekBar = document.querySelector '#seekbar'
hoverTime = document.querySelector '#hovertime'
hoverTimeText = document.querySelector '#hovertime .text'
hoverTimeNib = document.querySelector '#hovertime .nib'
elapsed = document.querySelector '#elapsed'

calculateEdges = ( x ) ->
	seekBox  = seekBar.getBoundingClientRect( )

	percent = Math.round(x / seekBox.width * 100)
	hoverTimeText.textContent = percent + '%'

	hoverBox = hoverTime.getBoundingClientRect( )

	left  = x - hoverBox.width * 0.5
	right = left + hoverBox.width
	shift = 0

	# seekBox.width is effectively the viewport width
	if right > seekBox.width
		shift = right - seekBox.width
	else if left < 0
		shift = left

	left -= shift

	if shift isnt 0
		hoverTimeNib.style.left = Math.min( hoverBox.width*0.5 + shift, hoverBox.width - 5 ) + 'px'
	else
		hoverTimeNib.style.left = '50%'

	hoverTime.style.left = left + 'px'
	hoverTime.style.bottom = '40px'

seekBar.addEventListener 'mouseover', ( ev ) ->
	hoverTime.className = 'incoming'

seekBar.addEventListener 'mouseout', ( ev ) ->
	hoverTime.className = 'outgoing'

lastX = -1
seekBar.addEventListener 'mousemove', ( ev ) ->
	if ev.clientX isnt lastX
		calculateEdges ev.clientX
		lastX = ev.clientX

seekBar.addEventListener 'click', ( ev ) ->
	seekBox  = seekBar.getBoundingClientRect( )
	percent = Math.round( ev.clientX / seekBox.width * 100 )
	# vpm.setPropertyString
	# mp.commandv "seek", percent, "absolute-percent", "keyframes"
	vpm.command [ "seek", String(percent), "absolute-percent", "keyframes" ]


setInterval ->
	position = vpm.getPropertyString 'percent-pos'
	return if position is undefined

	elapsed.style.width = position + '%'
, 200
