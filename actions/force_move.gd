class_name ActionForceMove extends Action

## TESTING required
## Try to move the target actor to the target tile.
## If the tile is occupied, or is beyond the edge of the tilemap,
## move as far as possible in that direction,
## TODO and optionally deal damage and apply a status.

@export var is_obstructable_along_path: bool = true ## If false, behaves like being thrown over the air to that tile.
@export var TEST_COORDS: Vector2i

var actor_to_move: Actor

## On transition to this state
func enter(_from: ResourceState = null) -> void:
	await do()
	exit()

## TESTING required
func do() -> void:
	##TESTING HACK
	var actor_idx = Level.get_all_actors_in_play_order().find_custom(func(v: Actor): return v.director is Player)
	var TEST_ACTOR: Actor = Level.get_all_actors_in_play_order()[actor_idx]
	
	actor_to_move = TEST_ACTOR
	_target = TEST_COORDS
	
	if not actor_to_move:
		push_error("Actor is invalid")
		return
	
	var result: Vector2i = actor_to_move.move_along_path(_target)
	
	if result != _target:
		on_hit_obstruction()


func on_hit_obstruction() -> void:
	p("on_hit_obstruction")
	pass
