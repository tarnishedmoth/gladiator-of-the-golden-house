class_name StatusEnemyStun extends Status
##Clears action queue of enemy to stun for 1 turn by default or x turns based on effect points  
func on_turn_start() -> void: 
	_actor.clear_action_queue()
	super()
