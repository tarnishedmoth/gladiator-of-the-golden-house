class_name ActionAttack extends Action

@export var damage: int
@export_category("Target Pattern")
@export var target_pattern: Array[Vector2i] = [] ## Assume coords 0,0 and facing north. Then list the coords they can hit. the rotate hex function in facing will make that pattern work in any direction.
@export_category(("AOE Pattern"))
@export var aoe_pattern: Array[Vector2i] = [] ## Assume coords 0,0 and facing north. Then list the coords they can hit. the rotate hex function in facing will make that pattern work in any direction.

## On transition to this state
func enter(from: ResourceState = null) -> void:
	#if debug:
	p("Attacking!")
	
	## run animations etc here
	get_affected_and_deal_damage()
	
	exit()

func get_affected_and_deal_damage() -> void:
	var targets: Array[Vector2i] = Facing.get_target_cells(
		_actor.current_tile_coords,
		_actor.facing,
		target_pattern
	)

	if debug: p("Targeting %d tiles." % targets.size())

	for coords in targets:
		var found_actor: Actor = Level.get_actor_at(coords)
		# Skip self - actors cannot damage themselves
		if found_actor != null and found_actor != _actor:
			if debug: p("Hitting %s for %d damage" % [found_actor.name, damage])
			found_actor.take_damage(damage)
