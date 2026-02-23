class_name ActionApplyStatus extends Action

@export var status: Status
@export_range(0, 99, 1, "or_greater") var override_quantity: int

## On transition to this state
func enter(from: ResourceState = null) -> void:
	if status:
		var target_actor = Level.get_actor_at(_target)
		if debug:
			p("Searched %s for actors and found %s" % [_target, target_actor])
		apply_status(target_actor)
	exit()

## Copies the status effect resource and applies it to the actor.
func apply_status(actor: Actor) -> void:
	if not actor:
		push_error("Actor is invalid")
	else:
		var _copy = status.duplicate()
		
		if override_quantity > 0:
			_copy.effect_points = override_quantity
		
		if debug: p("Applying status %s to %s" % [_copy.ui_name, _target])
		actor.add_status(_copy)
		
		await actor.animation_finished
		## todo actor.set_facing
