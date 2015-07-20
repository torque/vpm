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
	position = vpm.getProperty 'time-pos'
	return if position is undefined
	elapsed.textContent = formatTime position

updateTimer = setInterval updateElapsed, 200

observePos = ( position ) ->
	elapsed.textContent = formatTime position

window.observeProperty 'pause', ( paused ) ->
	if paused is 'yes'
		clearInterval updateTimer
		updateTimer = false
		window.observeProperty 'time-pos', observePos
	else if not updateTimer
		window.unobserveProperty 'time-pos', observePos
		updateTimer = setInterval updateElapsed, 200

window.observeProperty 'duration', ( duration ) ->
	haveHours = Math.floor(duration/3600) > 1
	total.textContent = formatTime duration
