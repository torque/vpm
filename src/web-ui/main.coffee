element = document.querySelector '.playbutton'
playing = true;
element.addEventListener 'click', (ev) ->
	playing = not playing
	element.className = 'playbutton ' + if playing then 'playing' else 'paused'
	vpm.setPropertyStringValue 'pause', if playing then 'no' else 'yes'
	# vpm.getPropertyStringAsyncWithCallback 'dwidth', (value) ->
	# 	console.log value