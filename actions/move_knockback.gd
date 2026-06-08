class_name ActionMoveKnockback extends ActionMove

## Attempt to move onto a tile, displacing anything there already in the direction of travel.
## If the tile can not be cleared, no movement occurs.

const STUN_STATUS: StatusStunned = preload("uid://b38qdbmcp8g2n") ## For both Player and AI

## i.e. Stunned for being knocked into a wall
@export var status_to_apply_if_knocked_into_obstacle: Status = STUN_STATUS


func move_actor(actor: Actor) -> void:
	if not actor:
		push_error("Actor is invalid")
		exit()
		return
	
	if debug: p("Moving to %s with knockback force!" % _target)
	
	## TODO obstructible maybe
	var _actor_at = Level.get_actor_at(_target)
	if _actor_at:
		knockback(_actor_at)
	
	if not Level.get_actor_at(_target):
		actor.move_to_tile.call_deferred(_target)
		await actor.animation_finished
		Level.get_instance().on_actor_moved(actor)
	exit()

func knockback(actor: Actor) -> void:
	var direction: Facing.Cardinal
	var source_tile: Vector2i = actor.current_tile_coords
	direction = Facing.get_direction_to_cell(_actor.tile_map, source_tile, actor.current_tile_coords)
	var target_tile: Vector2i = source_tile + (Facing.DIRECTIONS[direction])
	
	## Move the actor in that direction
	actor.knockback_in_direction(direction, 1)
	var result: Vector2i = actor.current_tile_coords
	
	if result != source_tile:
		await actor.animation_finished
	
	if result != target_tile:
		## Hit an obstruction
		on_hit_obstruction(actor)
		

func on_hit_obstruction(actor: Actor) -> void:
	if status_to_apply_if_knocked_into_obstacle:
		if debug:
			p("Applying status %s to %s from being knocked into an obstruction." % [status_to_apply_if_knocked_into_obstacle, actor])
		actor.add_status(status_to_apply_if_knocked_into_obstacle)
