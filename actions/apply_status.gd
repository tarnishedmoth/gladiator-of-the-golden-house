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
	var targets: Array[Vector2i]
	
	if _target != null:
		## New behavior: only the _target tile
		targets.append(_target)
	else:
		## (Old behavior): Every coord relative to _actor
		## Still utilized by AI Actors for some actions
		targets = _actor.get_action_target_cells(self)

	if debug: p("Targeting %d tiles." % targets.size())
	pulse_affected_tiles(targets)
	
	var affected: int = 0
	for coords in targets:
		var found_actor: Actor = Level.get_actor_at(coords)
		if found_actor:
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
