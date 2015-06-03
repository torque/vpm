element = document.querySelector '#elapsed'
setInterval ->
	position = vpm.getPropertyString 'percent-pos'
	return if position is undefined

	element.style.width = position + '%'
, 200
