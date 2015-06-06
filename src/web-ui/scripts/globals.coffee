events = []
callbacks = {}
window.observeMpvProperty = ( name, callback ) ->
	console.log "trying to observe #{name}"
	if callbacks[name]
		callbacks[name].push callback
	else
		events.push name
		callbacks[name] = [ callback ]
		vpm.observeProperty name, events.length - 1

# poor man's event dispatch.
window.signalMpvEvent = ( index, value ) ->
	# a queue within a queue within a queue within a queue within a queue
	setTimeout ->
		name = events[index]
		for callback in callbacks[name]
			callback value
	, 0
