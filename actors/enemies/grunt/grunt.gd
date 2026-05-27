class_name Grunt extends AIActor

##TEST for pickup
@export var on_death_pickup: PickUpData

func queue_new_actions_for_next_turn(claimed_tiles: Array[Vector2i] = []) -> void:
	var queue: Array[Action] = []

	# Attack
	var attacks := usable_actions.filter(
		func(a): return a.action_category == Action.ActionCategory.COMBAT
	)
	if not attacks.is_empty():
		var attack: Action = attacks.pick_random().duplicate()
		plan_action_details(attack, claimed_tiles)
		queue.append(attack)

	# Move
	var moves := usable_actions.filter(
		func(a): return a.action_category == Action.ActionCategory.MOVEMENT
	)
	if not moves.is_empty():
		var move: Action = moves.pick_random().duplicate()
		plan_action_details(move, claimed_tiles)
		queue.append(move)

	append_actions_to_queue(queue)
	
func die() -> void:
	## TEST HACK FIXME for pickup feature
	if(on_death_pickup):
		%PickUpManager.spawn_pick_up(on_death_pickup, current_tile_coords)
	super()
	
