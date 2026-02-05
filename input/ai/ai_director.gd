class_name AIDirector extends Director

## A singular AI team coordinator that can manage multiple characters.

func setup(tilemap: TileMapLayer) -> void:
	clear_and_repopulate_actors_from_children()
	for actor in actors:
		actor.setup(self, tilemap)
		
	if VERBOSE: p("Setup done.")

## We need to plan our moves and store them to be executed at the
## start of our next turn. This allows the player(s) to see our moves and strategize.
func _on_turn_started():
	if VERBOSE: p("AI taking turn...")
	
	var result = await execute_queued_moves()
	
	select_plans()
	
	end_turn()


func execute_queued_moves() -> bool:
	if VERBOSE: p("Executing queued actions.")
	for actor in actors:
		if actor is AIActor:
			actor.run_queued_actions()
			await actor.queued_actions_finished
	
	return true

func select_plans() -> void:
	## Query all of our actors to queue their next actions.
	if VERBOSE: p("Choosing actions for next turn.")
	for actor in actors:
		if actor is AIActor:
			actor.queue_new_actions_for_next_turn()
