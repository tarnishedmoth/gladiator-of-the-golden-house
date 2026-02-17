class_name ActionAttack extends Action

@export var damage: int
@export_category("Target Pattern")
@export var tgt_front: Array[int]
@export var tgt_front_right: Array[int]
@export var tgt_back_right: Array[int]
@export var tgt_back: Array[int] 
@export var tgt_back_left: Array[int]
@export var tgt_front_left: Array[int]
@export_category(("AOE Pattern"))
@export var target_spot_hit: bool
@export var AE_front: Array[int]
@export var AE_front_right: Array[int]
@export var AE_back_right: Array[int]
@export var AE_back: Array[int] 
@export var AE_back_left: Array[int]
@export var AE_front_left: Array[int]

## On transition to this state
func enter(from: ResourceState = null) -> void:
	#if debug:
	p("Attacking!")
	
	## run animations etc here
	get_affected_and_deal_damage()
	
	exit()

func get_tgt_pattern() -> Array:
	var pattern = []
	for r in tgt_front:
		pattern.append([Facing.Relative.FRONT, r])
	for r in tgt_front_right:
		pattern.append([Facing.Relative.FRONT_RIGHT, r])
	for r in tgt_back_right:
		pattern.append([Facing.Relative.BACK_RIGHT, r])
	for r in tgt_back:
		pattern.append([Facing.Relative.BACK, r])
	for r in tgt_back_left:
		pattern.append([Facing.Relative.BACK_LEFT, r])
	for r in tgt_front_left:
		pattern.append([Facing.Relative.FRONT_LEFT, r])
	return pattern
	
func get_aoe_pattern() -> Array:
	var pattern = []
	for r in AE_front:
		pattern.append([Facing.Relative.FRONT, r])
	for r in AE_front_right:
		pattern.append([Facing.Relative.FRONT_RIGHT, r])
	for r in AE_back_right:
		pattern.append([Facing.Relative.BACK_RIGHT, r])
	for r in AE_back:
		pattern.append([Facing.Relative.BACK, r])
	for r in AE_back_left:
		pattern.append([Facing.Relative.BACK_LEFT, r])
	for r in AE_front_left:
		pattern.append([Facing.Relative.FRONT_LEFT, r])
	return pattern

func get_affected_and_deal_damage() -> void:
	var targets: Array[Vector2i] = Facing.get_target_cells(
		_actor.current_tile_coords,
		_actor.facing,
		get_tgt_pattern()
	)

	if debug: p("Targeting %d tiles." % targets.size())

	for coords in targets:
		var found_actor: Actor = Level.get_actor_at(coords)
		# Skip self - actors cannot damage themselves
		if found_actor != null and found_actor != _actor:
			if debug: p("Hitting %s for %d damage" % [found_actor.name, damage])
			found_actor.take_damage(damage)
