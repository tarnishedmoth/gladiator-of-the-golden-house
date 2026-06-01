class_name ActionDoNothing extends Action

## for skipping turns. Waits for the set duration of time, then exits.

@export var wait_time: float = 1.0:
	get:
		return maxf(0.05, wait_time)

func enter(_from: ResourceState = null) -> void:
	var tween: Tween = _actor.create_tween()
	tween.tween_interval(wait_time)
	tween.tween_callback(exit)
