events = []
callbacks = {}
window.observeMpvProperty = ( name, callback ) ->
	console.log "trying to observe #{name}"
	unless callbacks[name]
		unless vpm.observeProperty name, events.length
			console.log "could not observe #{name}"
			return
		events.push name
		callbacks[name] = [ callback ]

	callbacks[name].push callback

# poor man's event dispatch.
window.signalMpvEvent = ( index, value ) ->
	# a queue within a queue within a queue within a queue within a queue
	setTimeout ->
		name = events[index]
		for callback in callbacks[name]
			callback value
	, 0
