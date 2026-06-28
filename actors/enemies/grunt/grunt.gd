class_name Grunt extends AIActor

## A more specific, but simple AI actor.
## Each turn, queues one movement category action, and one combat category action to play.

func queue_new_actions_for_next_turn(claimed_tiles: Array[Vector2i] = []) -> void:
	if debug:
		p("standing at %s, facing %s." % [current_tile_coords, facing])
	
	# Attack
	var attacks := usable_actions.filter(
		func(a): return a.action_category == Action.ActionCategory.COMBAT
	)
	if not attacks.is_empty():
		var attack: Action = attacks.pick_random().duplicate()
		plan_action_details(attack, claimed_tiles)
		append_action_to_queue(attack)

	# Move
	var moves := usable_actions.filter(
		func(a): return a.action_category == Action.ActionCategory.MOVEMENT
	)
	if not moves.is_empty():
		var move: Action = moves.pick_random().duplicate()
		plan_action_details(move, claimed_tiles)
		append_action_to_queue(move)
