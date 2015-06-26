largestIndex = 0
indices = {}
callbacks = {}

window.observeMpvProperty = ( name, callback ) ->
	console.log "trying to observe #{name}"
	unless callbacks[name]
		unless indices[name]
			indices[name] = largestIndex++
		unless vpm.observeProperty name, indices[name]
			console.log "could not observe #{name}"
			indices[name] = undefined
			return

		callbacks[name] = [ ]

	callbacks[name].push callback
	return callback

window.unobserveMpvProperty = ( name, callback ) ->
	return unless callback and callbacks[name] and indices[name]
	console.log "trying to unobserve #{name}"
	for cb, i in callbacks[name]
		if cb is callback
			callbacks[name].splice i, 1
			break

	if callbacks[name].length is 0
		callbacks[name] = undefined
		vpm.unobserveProperty indices[name]

# poor man's event dispatch.
window.signalMpvPropChange = ( name, value ) ->
	# a queue within a queue within a queue within a queue within a queue
	setTimeout ->
		return unless callbacks[name]
		for callback in callbacks[name]
			callback value
	, 0
