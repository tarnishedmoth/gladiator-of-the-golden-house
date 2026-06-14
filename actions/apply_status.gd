class_name ActionApplyStatus extends Action

@export var status: Status
@export_range(0, 99, 1, "or_greater") var override_quantity: int:
	get:
		if not override_quantity:
			return status.effect_points
		else:
			return override_quantity
			
@export var apply_effect_to_allies: bool = true
@export var apply_effect_to_enemies: bool = true

## On transition to this state
func enter(_from: ResourceState = null) -> void:
	if status:
		_get_affected_and_apply_status()
	exit()
	
func _get_affected_and_apply_status() -> void:
	var targets: Array[Vector2i]
	
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
			if not _actor_is_affected(found_actor): continue
			apply_status(found_actor)
			affected += 1
	
	if affected == 0:
		if debug: p("None affected.")
		Level.get_hud().popup_label("Missed", _actor, LevelHUD.STYLE_NEGATED)


## Copies the status effect resource and applies it to the actor.
func apply_status(actor: Actor) -> void:
	if not actor:
		push_error("Actor is invalid")
	else:
		if debug: p("Applying status %s to %s" % [status.ui_name, _target])
		StatusManager.apply_status_to_actor(status, actor, override_quantity)
		
		await actor.animation_finished

## Returns true if actor doesn't meet the criteria for flags "apply effect to allies" and "apply effect to enemies".
func _actor_is_affected(actor_to_receive_status: Actor) -> bool:
	var is_allied: bool = actor_to_receive_status.director == _actor.director
	if (not apply_effect_to_allies) and (is_allied):
		return false
	if (not apply_effect_to_enemies) and (not is_allied):
		return false
	return true
