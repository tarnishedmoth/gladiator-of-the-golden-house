class_name StatusStunned extends Status

## Universal stun effect for enemies or for the Player, with different behavior.
## For enemies, clears the action queue so they will not act this turn.
## For players, increases the energy cost 

##Clears action queue of enemy to stun for 1 turn by default or x turns based on effect points  

func on_turn_start() -> void:
	if not _actor:
		return
	if not _react_to_this_turn_notif():
		return
	
	if _actor is AIActor:
		_actor.clear_action_queue()
	elif _actor.director is Player:
		_actor.director.stunned(self)
	
	on_after_hook()
	
	super()
