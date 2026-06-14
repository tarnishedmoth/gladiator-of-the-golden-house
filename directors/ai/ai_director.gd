class_name AIDirector extends Director

## A singular AI team coordinator that can manage multiple characters.


## Implemented as part of experimenting with [method add_actor_for_next_turn] and [ActionSpawn].
## Tested working, basically if this is true it ensures that any new Actors inserted
## during the turn are not part of planning at end of turn. In practice it felt better
## to have them plan so they actually do something their next turn so leave this false.
const LIMIT_SELECTED_ACTORS_AT_START_OF_TURN: bool = false


@export var allied_with_player: bool = false


func setup(tilemap: TileMapLayer) -> void:
	clear_and_repopulate_actors_from_children()
	for actor in actors:
		actor.setup(self, tilemap)
		actor.is_active = true
		
	if VERBOSE: p("Setup done.")

## We need to plan our moves and store them to be executed at the
## start of our next turn. This allows the player(s) to see our  moves and strategize.
func _on_turn_started():
	if VERBOSE: p("AI taking turn...")
	
	## A copy prevents bugs from adding/removing actors during the turn...
	var actors_this_turn: Array[Actor]
	if LIMIT_SELECTED_ACTORS_AT_START_OF_TURN:
		actors_this_turn = actors.filter(func(v: Actor): return true if v.is_active else false)
	else:
		actors_this_turn = actors
	
	## Let's put the random one-liners here
	Level.get_instance().trigger_random_actor_speech_bubbles()
	
	var _minimum_wait_time: Tween = create_tween()
	_minimum_wait_time.tween_interval(1.2)
	
	var _result = await execute_queued_moves(actors_this_turn)
	
	if _minimum_wait_time:
		if _minimum_wait_time.is_running():
			await _minimum_wait_time.finished
	
	select_plans(actors_this_turn)
	
	end_turn()


func execute_queued_moves(actors_array: Array[Actor]) -> bool:
	if VERBOSE: p("Executing queued actions.")
	
	for actor in actors_array:
		if not actor: continue
		if not actor.is_active: continue
		if actor is AIActor:
			actor.show_acting_indicator(true)
			actor.run_queued_actions()
			await actor.queued_actions_finished
			actor.show_acting_indicator(false)
	
	return true

func select_plans(actors_array: Array[Actor]) -> void:
	## Query all of our actors to queue their next actions.
	## Track planned destinations so later actors avoid tiles earlier actors claimed.
	if VERBOSE: p("Choosing actions for next turn.")
	var claimed_tiles: Array[Vector2i] = []
	for actor in actors_array:
		if not actor: continue
		if not actor.is_active: continue
		if actor is AIActor:
			actor.queue_new_actions_for_next_turn(claimed_tiles)
		else:
			push_error("Non-AIActor found in actor array: %s" % actor)

## Sets up the actor to be called upon next turn. Does not move actor or reorient
func add_actor_for_next_turn(actor: Actor, front: bool = false) -> void:
	if front:
		if VERBOSE: p("Inserting actor %s at front..." % actor)
		actors.push_front(actor)
	else:
		if VERBOSE: p("Appending actor %s..." % actor)
		actors.push_back(actor)
	
	actor.setup(self, Level.get_base_tile_map_layer(), false)
	actor.is_active = true
	
	#turn_taken.connect(_activate_actor.bind(actor), CONNECT_ONE_SHOT)
#
#func _activate_actor(_director: Director, actor: Actor) -> void:
	#actor.is_active = true
