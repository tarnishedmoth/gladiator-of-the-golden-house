class_name ActionApplyStatusPattern extends ActionApplyStatus

@export var pattern: Array[Vector2i] = []: ## Assume coords 0,0 and facing north. Then list the coords they can hit. the rotate hex function in facing will make that pattern work in any direction.
	get:
		if split_choice:
			if run_mirrored:
				if mirrored_pattern.is_empty():
					mirrored_pattern = Facing.mirror(pattern) ## Caching, WARNING does not check equivalency
				return mirrored_pattern
		return pattern
var mirrored_pattern: Array[Vector2i] ## Cached.

@export var aoe_pattern: Array[Vector2i]:
	get:
		if split_choice:
			if run_mirrored:
				if mirrored_aoe_pattern.is_empty():
					mirrored_aoe_pattern = Facing.mirror(pattern) ## Caching, WARNING does not check equivalency
				return mirrored_aoe_pattern
		return aoe_pattern
var mirrored_aoe_pattern: Array[Vector2i] ## Cached.

@export var split_choice: bool = false ## If true, allows for the pattern to *also* apply counter-clockwise. This is specifically for asymmetrical patterns.



# Called when the node enters the scene tree for the first time.
func enter(_from: ResourceState = null) -> void:
	if status:
		_get_affected_and_apply_status()
	exit()

func _get_affected_and_apply_status() -> void:
	var targets: Array[Vector2i]
	var facing: Facing.Cardinal = _actor.get_facing() ## TODO maybe use Facing.get_direction_to_coordinate()
	
	if aoe_pattern && _target != null:
		## Translate our aoe pattern to the _target coordinate
		targets = Facing.get_target_cells(_target, facing, aoe_pattern)
	else:
		if _target != null:
			## New behavior: only the _target tile
			targets.append(_target)
		else:
			## (Old behavior): Every coord relative to _actor
			## Still utilized by AI Actors for some actions
			targets = _actor.get_action_target_cells(self)

	if debug: p("Targeting %d tiles." % targets.size())
	
	var affected: int = 0
	for coords in targets:
		var found_actor: Actor = Level.get_actor_at(coords)
		if found_actor:
			apply_status(found_actor)
			affected += 1
	
	if affected == 0:
		if debug: p("None affected.")
		Level.get_hud().popup_label("Missed", _actor, LevelHUD.STYLE_NEGATED)
