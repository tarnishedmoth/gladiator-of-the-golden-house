class_name AIDirector extends Director

## A singular AI team coordinator that can manage multiple characters.

@export var allied_with_player: bool = false

func setup(tilemap: TileMapLayer) -> void:
	clear_and_repopulate_actors_from_children()
	for actor in actors:
		actor.setup(self, tilemap)
		
	if VERBOSE: p("Setup done.")

## We need to plan our moves and store them to be executed at the
## start of our next turn. This allows the player(s) to see our  moves and strategize.
func _on_turn_started():
	if VERBOSE: p("AI taking turn...")
	
	## Let's put the random one-liners here
	Level.get_instance().trigger_speech_bubbles()
	
	var _minimum_wait_time: Tween = create_tween()
	_minimum_wait_time.tween_interval(1.2)
	
	var _result = await execute_queued_moves()
	
	if _minimum_wait_time:
		if _minimum_wait_time.is_running():
			await _minimum_wait_time.finished
	
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
	## Track planned destinations so later actors avoid tiles earlier actors claimed.
	if VERBOSE: p("Choosing actions for next turn.")
	var claimed_tiles: Array[Vector2i] = []
	for actor in actors:
		if actor is AIActor:
			actor.queue_new_actions_for_next_turn(claimed_tiles)
		else:
			push_error("Non-AIActor found in actor array: %s" % actor)
