seekBar = document.querySelector '#seekbarPad'
hoverTime = document.querySelector '#hovertime'
hoverTimeText = document.querySelector '#hovertime .text'
hoverTimeNib = document.querySelector '#hovertime .nib'

setPosition = ( x ) ->
	seekBox = seekBar.getBoundingClientRect( )

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
	# this positioning is kind of dependent on the seekbarPad div height,
	# since the nib sits inside that div. Currently, it looks fine.
	hoverTime.style.top = seekBox.top - hoverBox.height + 'px'

seekBar.addEventListener 'mouseover', ( ev ) ->
	hoverTime.className = 'shown'

seekBar.addEventListener 'mouseout', ( ev ) ->
	hoverTime.className = ''

lastX = -1
seekBar.addEventListener 'mousemove', ( ev ) ->
	if ev.clientX isnt lastX
		setPosition ev.clientX
		lastX = ev.clientX
