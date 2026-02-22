class_name ActionAttack extends Action

@export var damage: int
@export var can_damage_self: bool = false
#@export_category("Target Pattern")
@export var pattern: Array[Vector2i] = [] ## Assume coords 0,0 and facing north. Then list the coords they can hit. the rotate hex function in facing will make that pattern work in any direction.
@export var aoe_pattern: Array[Vector2i]
@export var split_choice: bool = false ## TODO If true, allows for the pattern to *also* apply counter-clockwise. This is specifically for asymmetrical patterns.

## On transition to this state
func enter(from: ResourceState = null) -> void:
	if _actor:
		p("Attacking!")
		
		## run animations etc here
		_get_affected_and_deal_damage()
	else:
		push_error("No actor configured to run action.")
	
	exit()

func _get_affected_and_deal_damage() -> void:
	var targets: Array[Vector2i] = _actor.get_translated_pattern(pattern)

	if debug: p("Targeting %d tiles." % targets.size())

	for coords in targets:
		var found_actor: Actor = Level.get_actor_at(coords)
		
		if found_actor != null:
			if not can_damage_self && found_actor == _actor:
				return
			if debug: p("Hitting %s for %d damage" % [found_actor.name, damage])
			found_actor.take_damage(damage)
