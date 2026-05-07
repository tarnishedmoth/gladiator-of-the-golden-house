class_name Playtime

@warning_ignore_start("integer_division")

var hours: int:
	set(h):
		hours = maxi(0, h)

var minutes: int: ## 0 to 59
	set(m):
		minutes = maxi(0, m)
		if minutes > 59:
			var passed = minutes/60
			hours += passed
			minutes -= passed*60

var seconds: float: ## 0.0 rollover at 60.0
	set(s):
		seconds = maxf(0.0, s)
		if seconds > 60.0:
			var passed = int(seconds / 60.0)
			minutes += passed
			seconds -= passed*60

var time_scale: float = 1.0 ## Used in [method progress] to advance time.

## Optionally you can specifiy a time scale, otherwise it will use
## [member time_scale].
func progress(delta:float, timescale:float = time_scale) -> void:
	seconds += delta * timescale

func set_all(
		h:int,
		mi:int,
		s:float,
	) -> void:
	hours = h
	minutes = mi
	seconds = s
	#print_debug("In-game time:", get_string_time())
	
func set_seconds(s:float) -> void:
	seconds = s
	#print_debug("In-game time:", get_string_time())

func set_time_to_system() -> void:
	var t = Time.get_datetime_dict_from_system()
	#print_debug("OS time:", t)
	set_all(
		t['hour'],
		t['minute'],
		t['second'],
	)

func get_string_time() -> String:
	if hours > 0:
		return "%02d:%02d:%02.3d" % [hours, minutes, seconds]
	else:
		return "%02d:%02.3d" % [minutes, seconds]
