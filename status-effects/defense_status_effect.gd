class_name DefenseStatus extends Status

## Base clase for defense based status effects

enum OnStart {
	NOTHING,
	SUBTRACT_ONE,
	HALVE,
	REMOVE_EFFECT,
}

@export var on_start_behavior: OnStart = OnStart.REMOVE_EFFECT

func on_turn_start() -> void:
	match on_start_behavior:
		OnStart.SUBTRACT_ONE:
			subtract_points(1)
		OnStart.HALVE:
			halve_points()
		OnStart.REMOVE_EFFECT:
			remove_effect()


func on_take_damage(damage:int) -> int:
	return (reduce_damage(damage))
	
func reduce_damage(incoming_damage:int) -> int:
	#If there is no defense points remaining return the remaining damage and remove
	#status effect else return zero
	if(incoming_damage >= effect_points): 
		_actor.remove_status(self)
		incoming_damage -= effect_points
		print("%s damage passed through to %s" % [incoming_damage,_actor.ui_name])
		return incoming_damage
	else :
		effect_points -= incoming_damage
		print("%s: Defense blocked %s damage, %s defense remaining" % [_actor.ui_name,incoming_damage,effect_points]) 
		return 0
