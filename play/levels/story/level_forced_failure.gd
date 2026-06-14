extends Level

## Forced failure level. Once the player Wins, an event is triggered to spawn new enemies,
## and a conditional is made true so that on the next win, the level will finally progress.

signal event

const SHOCKED_REACTIONS: OneLinersStrings = preload("uid://cmkeua4ngk1h6")
const ENEMY_TO_SPAWN: PackedScene = preload("uid://bqwvnxdyhfrmi")

## When true, when the Player dies, they will not be prompted to restart the level.
## The level will progress automatically rather than prompting the player with the
## typical post-game menu.
var level_can_complete: bool = false

@onready var hidden_ai_director: AIDirector = %HiddenAIDirector

func check_objectives() -> void:
	if is_complete: return
	p("Checking game objectives")
	#await get_tree().process_frame
	await create_tween().tween_interval(0.1).finished
	if not _is_alive(): return  ## Bail if this Level was torn down during the awaited frame.

	if check_win_condition() == true:
		if not level_can_complete:
			## Trigger forced failure event...
			p("Running special event...")
			run_event()
		else:
			## They somehow survived ???
			## This shouldn't be possible
			push_error("Unintended level outcome. Progressing")
			_progress_to_next_level()
		
	elif check_lose_condition() == true:
		if not level_can_complete:
			## Failure, restart...
			is_complete = true
			_record_playtime()
			retry_menu.show()
		
		else:
			## Actual level completion, progress...
			_progress_to_next_level()

func _progress_to_next_level() -> void:
	p("Level complete.")
	is_complete = true
	_record_playtime()
	
	## Save
	#save_persistent_actors_data() ## We have to do something different because of the forced failure. Should reset the health to full
	PlayerData.wipe_actor_data()
	Main.register_level_progressed()
	
	## managed transition
	Main.play_sherman(true) ## start music before cutscene loads
	
	var fade_out_tween: Tween = create_tween()
	fade_out_tween.tween_property(self, ^"modulate", Color.BLACK, 10.0)
	fade_out_tween.parallel()
	var audio_bus_index: int = AudioServer.get_bus_index(&"SfxControlled")
	fade_out_tween.tween_method(
		func(v): AudioServer.set_bus_volume_linear(audio_bus_index, v),
		1.0, 0.0, 10.0)
	
	fade_out_tween.tween_callback(Main.load_latest_level)
	fade_out_tween.tween_callback(AudioServer.set_bus_volume_linear.bind(audio_bus_index, 1.0))

func run_event() -> void:
	event.emit()
	
	## - Spawn swarm of new enemies
	var edge_tiles: Array[Vector2i] = []
	for tile in base_tile_map_layer.get_used_cells():
		#p("Checking tile %s..." % tile)
		if Level.get_actor_at(tile): continue
		for cell in base_tile_map_layer.get_surrounding_cells(tile):
			if base_tile_map_layer.get_cell_tile_data(cell):
				continue
			else:
				## var tile is an edge coordinate
				edge_tiles.append(tile)
				#p("Found edge tile %s" % tile)
				break
	#p(edge_tiles)
	
	## get the player actor
	var player_director: Player = directors[directors.find_custom(func(v): return v is Player)]
	var player_actor: Actor = player_director.actors.front() ## technically a HACK
	
	## Spawn enemies around the entire arena edge
	var actor_fader: Tween = create_tween() ## vfx
	for tile in edge_tiles:
		var actor: AIActor = ENEMY_TO_SPAWN.instantiate()
		actor.modulate = Color.TRANSPARENT
		
		hidden_ai_director.add_child(actor)
		actor.global_position = Actor.get_global_position_at(base_tile_map_layer, tile)
		
		## set to face the player
		actor.facing = Facing.get_direction_to_cell(
			base_tile_map_layer,
			tile,
			player_actor.current_tile_coords)
		
		actor_fader.tween_property(actor, ^"modulate", Color.WHITE, randfn(0.25, 0.15)) ## vfx
	
	hidden_ai_director.visible = true
	Level.get_instance().add_director(hidden_ai_director, true)
	var claimed_tiles: Array[Vector2i]
	for actor: AIActor in hidden_ai_director.actors: ## HACK
		actor.queue_new_actions_for_next_turn(claimed_tiles)
	
	## - Crowd reactions in shock, asking what are those
	trigger_random_crowd_speech_bubbles(SHOCKED_REACTIONS)
	## swap out their one liners
	for bubble: OneLiners in get_tree().get_nodes_in_group(OneLiners.GROUP_NAME):
		if bubble.is_crowd:
			bubble.one_liners = SHOCKED_REACTIONS
	
	level_can_complete = true
