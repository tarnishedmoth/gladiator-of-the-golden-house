class_name StatusEnemyStun extends Status
## DEPRECATED -- see [StatusStunned]
## Clears action queue of enemy to stun for 1 turn by default or x turns based on effect points.
## Always reacts to on_turn_start hook.

func on_turn_start() -> void: 
	if not _react_to_this_turn_notif():
		return
	
	_actor.clear_action_queue()
	#on_after_hook() ## Needs TESTING
	super()
