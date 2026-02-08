class_name ActionMove extends Action

## Minimum distance, maximum distance in tiles.
## e.g. if the value is (2, 2), you can only move exactly two tiles.
## If the value is (1, 2), you can move either one or two tiles.
@export var distance: Vector2i = Vector2i(1, 1)
@export var pattern: Array[Vector2i]
var destination_coords: Vector2i

## On transition to this state
func enter(from: ResourceState = null) -> void:
	move_actor(_actor)
	#await move animation finished
	exit()

func move_actor(actor: Actor) -> void:
	if not destination_coords:
		push_error("No coordinates to move to!")
	elif not actor:
		push_error("Actor is invalid")
	else:
		if debug: p("Moving to %s!" % destination_coords)
		actor.move_to_tile(destination_coords)
