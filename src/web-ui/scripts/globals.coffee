callbacks = {}
window.observeMpvProperty = ( name, callback ) ->
	console.log "trying to observe #{name}"
	unless callbacks[name]
		unless vpm.observeProperty name
			console.log "could not observe #{name}"
			return
		callbacks[name] = [ callback ]

	callbacks[name].push callback

# poor man's event dispatch.
window.signalMpvPropChange = ( name, value ) ->
	# a queue within a queue within a queue within a queue within a queue
	setTimeout ->
		for callback in callbacks[name]
			callback value
	, 0
