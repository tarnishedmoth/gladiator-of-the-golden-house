class_name ActionMove extends Action

## Minimum distance, maximum distance in tiles.
## e.g. if the value is (2, 2), you can only move exactly two tiles.
## If the value is (1, 2), you can move either one or two tiles.
@export var distance: Vector2i = Vector2i(1, 1) ## DEPRECATED we should use patterns instead and refactor the ai decision for it
@export var pattern: Array[Vector2i]

## On transition to this state
func enter(from: ResourceState = null) -> void:
	move_actor(_actor)
	exit()

func move_actor(actor: Actor) -> void:
	if not actor:
		push_error("Actor is invalid")
	else:
		if debug: p("Moving to %s!" % _target)
		actor.call_deferred("move_to_tile", _target)
		
		await actor.animation_finished
		## todo actor.set_facing
