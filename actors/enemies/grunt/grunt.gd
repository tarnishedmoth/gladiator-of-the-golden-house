class_name Grunt extends AIActor

func queue_new_acitons_for_next_turn() -> void:
	var queue: Array[Action] = []

	# Attack
	var attacks := usable_actions.filter(
		func(a): return a.action_category == Action.ActionCategory.COMBAT
	)
	if not attacks.is_empty():
		var attack: Action = attacks.pick_random().duplicate()
		queue.append(attack)

	# Move
	var moves := usable_actions.filter(
		func(a): return a.action_category == Action.ActionCategory.MOVEMENT
	)
	if not moves.is_empty():
		var move: Action = moves.pick_random().duplicate()
		plan_action_details(move)
		queue.append(move)

	append_actions_to_queue(queue)
