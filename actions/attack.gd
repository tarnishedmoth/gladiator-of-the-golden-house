class_name ActionAttack extends Action

@export var damage: int
@export var pattern: Array[Vector2i] ## Relative to the actor at (0,0)

## On transition to this state
func enter(from: ResourceState = null) -> void:
	#if debug:
	p("Attacking!")
	
	## run animations etc here
	get_affected_and_deal_damage()
	
	exit()

func get_affected_and_deal_damage() -> void:
	## TODO
	## get affected tiles
	#var rotated_attack_pattern: Array[Vector2i] = Tile Pattern . rotate(cardinal_direction)
	var affected: Array[Actor]# = get actors in rotated_attack_pattern
	
	if debug: p("Found %d actors to affect..." % affected.size())
	
	## deal damage to anything there
	for actor in affected:
		actor.take_damage(damage)
