class_name ActionApplyStatus extends Action

## Sort of DEPRECATED, this class as implemented only applies the status effect to the actor who runs it.
## See [ActionApplyStatusPattern]. Retaining because of actions which use it already.

@export var status: Status
@export_range(0, 99, 1, "or_greater") var override_quantity: int:
	get:
		if not override_quantity:
			return status.effect_points
		else:
			return override_quantity

## On transition to this state
func enter(_from: ResourceState = null) -> void:
	if status:
		_get_affected_and_apply_status()
	exit()
	
func _get_affected_and_apply_status() -> void:
	var affected_tiles: Array[Vector2i]
	
	if _target != null:
		## New behavior: only the _target tile
		affected_tiles.append(_target)
	else:
		## (Old behavior): Every coord relative to _actor
		## Still utilized by AI Actors for some actions
		affected_tiles = _actor.get_action_target_cells(self)

	if debug: p("Targeting %d tiles." % affected_tiles.size())
	var affected_actors: Array[Actor]
	for coords in affected_tiles:
		var found_actor: Actor = Level.get_actor_at(coords)
		if found_actor:
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


## Copies the status effect resource and applies it to the actor.
func apply_status(actor: Actor) -> void:
	if not actor:
		push_error("Actor is invalid")
	else:
		if debug: p("Applying status %s to %s" % [status.ui_name, actor])
		StatusManager.apply_status_to_actor(status, actor, override_quantity)
		
		await actor.animation_finished
