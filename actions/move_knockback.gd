class_name ActionMoveKnockback extends ActionMove

## Attempt to move onto a tile, displacing anything there already in the direction of travel.
## If the tile can not be cleared, no movement occurs.

enum RefundTypes {
	NONE = 0, ## No refunds
	HIT_ACTOR = 1, ## Tried to move and hit an actor
	HIT_AND_MOVED = 2, ## Hit and actor, and successfully knocked it out of the way.
	UNOCCUPIED = 3, ## Moved onto an empty tile, no actor was knocked.
}

## i.e. Stunned for being knocked into a wall
@export var status_to_apply_if_knocked_into_obstacle: Status

@export_group("Refundable Energy Cost")
@export var refundable_cost: RefundTypes = RefundTypes.NONE
@export var refundable_quantity: int = -1

func move_actor(actor: Actor) -> void:
	if not actor:
		push_error("Actor is invalid")
		exit()
		return

	if debug: p("Moving to %s with knockback force!" % _target)

	## TODO obstructible maybe
	var _actor_at = Level.get_actor_at(_target)
	var _knockedback: bool = false
	if _actor_at:
		## Refund logic
		if refundable_cost == RefundTypes.HIT_ACTOR:
			refund(refundable_quantity if refundable_quantity != -1 else energy_cost)

		## Knockback
		knockback(_actor_at)
		_knockedback = true

	if not Level.get_actor_at(_target):
		## Refund logic
		if refundable_cost == RefundTypes.UNOCCUPIED and not _knockedback\
		or refundable_cost == RefundTypes.HIT_AND_MOVED and _knockedback:
			refund(refundable_quantity if refundable_quantity != -1 else energy_cost)

		## Movement
		actor.move_to_tile.call_deferred(_target)
		await actor.animation_finished
		Level.get_instance().on_actor_moved(actor)
	exit()


func knockback(actor: Actor) -> void:
	if not actor.is_alive():
		if debug: p("Actor is dead, skipping knockback logic.")
		return
	
	var direction: Facing.Cardinal
	var _previous_tile: Vector2i = actor.current_tile_coords ## Defending actor who is being knocked back
	var _source: Vector2i = _actor.current_tile_coords ## Offending actor who is moving
	direction = Facing.get_direction_to_cell(_actor.tile_map, _source, _previous_tile)
	var target_tile: Vector2i = _previous_tile + (Facing.DIRECTIONS[direction])

	## Move the actor in that direction
	actor.knockback_in_direction(direction, 1)
	var result: Vector2i = actor.current_tile_coords

	if result != _previous_tile:
		await actor.animation_finished

	if result != target_tile and actor.can_knockback: ## HACK ? This code flow lets actors make popups when trying to knockback them if they can't.
		## Hit an obstruction
		on_hit_obstruction(actor)


func on_hit_obstruction(actor: Actor) -> void:
	if status_to_apply_if_knocked_into_obstacle:
		if debug:
			p("Applying status %s to %s from being knocked into an obstruction." % [status_to_apply_if_knocked_into_obstacle, actor])
		actor.add_status(status_to_apply_if_knocked_into_obstacle)
