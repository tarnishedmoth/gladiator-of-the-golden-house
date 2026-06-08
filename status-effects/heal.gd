class_name StatusAffectHealing extends Status


func _apply_healing() -> void:
	_actor.apply_healing(effect_points)
	on_after_hook()


func on_turn_start() -> void:
	_apply_healing()
	super()


func on_status_applied(status: Status) -> void:
	if is_same_status(status, self):
		_apply_healing()
	super(status)
