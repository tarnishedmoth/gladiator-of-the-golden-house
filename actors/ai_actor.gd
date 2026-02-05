class_name AIActor extends Actor

@export var usable_actions: Array[Action] ## TEST

func queue_new_actions_for_next_turn() -> void:
	var queue: Array[Action]
	
	var to_queue:int = 1
	for i in to_queue:
		queue.append(get_random_action())
		
	append_actions_to_queue(queue)

func get_random_action() -> Action:
	return usable_actions.pick_random()
