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

@export var apply_effect_to_allies: bool = true
@export var apply_effect_to_enemies: bool = true


# Called when the node enters the scene tree for the first time.
func enter(_from: ResourceState = null) -> void:
	if status:
		_get_affected_and_apply_status()
	exit()

func _get_affected_and_apply_status() -> void:
	var affected_tiles: Array[Vector2i]
	
	if aoe_pattern && _target != null:
		affected_tiles = _actor.get_action_target_cells_at(_target, self)
	else:
		if _target != null:
			## New behavior: only the _target tile
			affected_tiles.append(_target)
		else:
			## (Old behavior): Every coord relative to _actor
			## Still utilized by AI Actors for some actions
			affected_tiles = _actor.get_action_target_cells_at(_actor.current_tile_coords, self)

	if debug: p("Targeting %d tiles." % affected_tiles.size())
	
	var affected_actors: Array[Actor]
	for coords in affected_tiles:
		var found_actor: Actor = Level.get_actor_at(coords)
		if found_actor:
			if not _actor_is_affected(found_actor): continue
			affected_actors.append(found_actor)
	
	var tiles_with_actors: Array[Vector2i]
	for actor in affected_actors:
		tiles_with_actors.append(actor.current_tile_coords)
	## Pass in all valid tiles, and all tiles actually about to be affected
	pulse_affected_tiles(affected_tiles, tiles_with_actors) ## VFX
	
	if affected_actors.is_empty():
		if debug: p("None affected.")
		Level.get_hud().popup_label("Missed", _actor, LevelHUD.STYLE_NEGATED)
	else:
		for actor in affected_actors:
			apply_status(actor)


## Returns true if actor doesn't meet the criteria for flags "apply effect to allies" and "apply effect to enemies".
func _actor_is_affected(actor_to_receive_status: Actor) -> bool:
	var is_allied: bool = actor_to_receive_status.director == _actor.director
	if (not apply_effect_to_allies) and (is_allied):
		return false
	if (not apply_effect_to_enemies) and (not is_allied):
		return false
	return true
