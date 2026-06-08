class_name ActionMove extends Action

## Minimum distance, maximum distance in tiles.
## e.g. if the value is (2, 2), you can only move exactly two tiles.
## If the value is (1, 2), you can move either one or two tiles.
@export var distance: Vector2i = Vector2i(1, 1) ## DEPRECATED we should use patterns instead and refactor the ai decision for it
@export var pattern: Array[Vector2i]

## TODO make movements obstructable

## On transition to this state
func enter(_from: ResourceState = null) -> void:
	move_actor(_actor)

func move_actor(actor: Actor) -> void:
	if not actor:
		push_error("Actor is invalid")
		exit()
	else:
		if debug: p("Moving to %s!" % _target)
		var prev_coord: Vector2i = actor.current_tile_coords
		var result: Vector2i
		if not is_obstructable:
			actor.move_to_tile(_target)
			result = actor.current_tile_coords
		else:
			result = actor.move_along_path(_target)
		
		if result != prev_coord:
			await actor.animation_finished
		
		Level.get_instance().on_actor_moved(actor)
		exit()
