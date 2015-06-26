elapsed = document.querySelector '#timeElapsed'
total = document.querySelector '#timeTotal'

haveHours = false
zeroPad = ( number ) ->
	if number < 10
		return "0" + String number
	else
		return String number

formatTime = ( time ) ->
	timeString = zeroPad Math.floor(time) % 60
	minutes = Math.floor(time/60) % 60
	if haveHours
		hours = Math.floor(time/3600)
		timeString = "#{hours}:#{zeroPad minutes}:#{timeString}"
	else
		timeString = "#{minutes}:#{timeString}"

	return timeString

updateElapsed = ->
	position = vpm.getPropertyString 'time-pos'
	return if position is undefined
	elapsed.textContent = formatTime position

updateTimer = setInterval updateElapsed, 200

observePos = ( position ) ->
	elapsed.textContent = formatTime position

window.observeMpvProperty 'pause', ( paused ) ->
	if paused is 'yes'
		clearInterval updateTimer
		updateTimer = false
		window.observeMpvProperty 'time-pos', observePos
	else if not updateTimer
		window.unobserveMpvProperty 'time-pos', observePos
		updateTimer = setInterval updateElapsed, 200

window.observeMpvProperty 'duration', ( duration ) ->
	haveHours = Math.floor(duration/3600) > 1
	total.textContent = formatTime duration
