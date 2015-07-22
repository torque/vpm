callbacks = {}
window.observeProperty = ( name, callback ) ->
	console.log "trying to observe #{name}"
	unless callbacks[name]
		unless vpm.observeProperty name
			console.log "could not observe #{name}"
			return

		callbacks[name] = [ ]

	callbacks[name].push callback
	return callback

window.unobserveProperty = ( name, callback ) ->
	return unless callback and callbacks[name]
	console.log "trying to unobserve #{name}"
	for cb, i in callbacks[name]
		if cb is callback
			callbacks[name].splice i, 1
			break

	if callbacks[name].length is 0
		callbacks[name] = undefined
		vpm.unobserveProperty name

window.signalPropertyChange = ( name, value, oldValue ) ->
	setTimeout ->
		return unless callbacks[name]
		for callback in callbacks[name]
			callback value, oldValue
	, 0
