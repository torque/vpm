element = document.querySelector '#fullscreenbutton'

element.addEventListener 'click', ( ev ) ->
	vpm.toggleFullScreen( )

vpm.setFullScreenCallback ( fullscreen ) ->
	element.className = if fullscreen then 'fullscreen' else 'windowed'
