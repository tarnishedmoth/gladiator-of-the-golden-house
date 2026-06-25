class_name AIActorConditional extends AIActor

## If the conditions are met, this list of actions will be used.
## Otherwise, the base [member usable_actions] will be used.
@export var conditionally_usable_actions: Array[Action]

@export_group("Conditions", "cond_")
## Truthy if [member director]'s actor count (not including this actor) is equal to or less than this number.
## Set to -1 to disable this condition check.
@export_range(-1, 9, 1.0, "or_greater", "suffix:actors") var cond_team_count: int = 0

@export_group("Extra Actions")
## If set, and the conditions are passed, an additional action will be
## queued [i]before[/i] regularly queued actions ([member actions_to_queue_this_turn]).
@export var and_always_begin_with: Action

## If set, and the conditions are passed, an additional action will be
## queued [i]after[/i] regularly queued actions ([member actions_to_queue_this_turn]).
@export var and_always_end_with: Action

## How many actions to queue if the conditional is met.
## Set to -1 to disable.
@export_range(-1, 9, 1.0, "or_greater", "suffix:actions") var alt_actions_to_queue_this_turn: int = -1


func queue_new_actions_for_next_turn(claimed_tiles: Array[Vector2i] = []) -> void:
	var conditions_met: bool = _check_conditions()
	
	var actions_to_use: Array[Action]
	actions_to_use = conditionally_usable_actions if conditions_met else usable_actions
	
	var queue: Array[Action]
	
	if conditions_met and and_always_begin_with:
		var _action: Action = and_always_begin_with.duplicate()
		plan_action_details(_action, claimed_tiles)
		queue.append(_action)
	
	var _actions_to_queue: int
	if conditions_met and alt_actions_to_queue_this_turn >= 0:
		_actions_to_queue = alt_actions_to_queue_this_turn
	else:
		_actions_to_queue = actions_to_queue_this_turn
	
	for i in _actions_to_queue:
		queue.append(choose_action(claimed_tiles, actions_to_use))
	
	if conditions_met and and_always_end_with:
		var _action: Action = and_always_end_with.duplicate()
		plan_action_details(_action, claimed_tiles)
		queue.append(_action)
	
	append_actions_to_queue(queue)
	check_queued_set_facing()


func _check_conditions() -> bool:
	if cond_team_count != -1:
		if (director.actors.size() - 1) > cond_team_count:
			return false
	
	## add more fail checks here
	if debug:
		p("Conditions met for alternate behavior.")
	return true
