class_name Level extends Node2D

## Handles basic setup, turn events, and exit of the play scene.

## Debug printing
const VERBOSE: bool = true
func p(args):
	if VERBOSE: print_rich("[bgcolor=red][color=white]", "Level: ", args)

#region Signals and Variables

signal current_director_changed(director: Director)

@export var use_randomized_rotation_and_mirror: bool = true

@export var base_tile_map_layer: TileMapLayer
@export var tile_interactor: TileInteractor ## Used for detecting mouse input.
@export var hud: LevelHUD

@export var retry_menu: Control
@export var continue_menu: Control
@export var pause_menu: Control

var is_complete: bool = false ## If true, the level has concluded. Used to prevent duplicate logic.
var turn_count: int = 0 ## Incremented by one each time the current director changes.

var directors: Array[Director] = [] ## A list of all player and AI directors in the scene.
var current_director_idx: int = -1 ## The index of the current director within [member directors].
var waiting_to_finish: Array[Director] = [] ## A list of all directors who need to complete their turn before the cycle repeats.
@onready var pick_up_manager: PickUpManager = %PickUpManager

@warning_ignore_start("unused_private_class_variable")
## Random level rotation/mirroring
@onready var _level_start_facing: Facing.Cardinal = Facing.Cardinal.values().pick_random() as Facing.Cardinal
@onready var _level_start_mirror: bool = randf() > 0.5
@warning_ignore_restore("unused_private_class_variable")

#endregion
#region Static Instances

## Static instance, we should only have one Level in the scene tree at any time.
static var instance: Level:
	set(value):
		if value != null && instance != null:
			assert(
				not (is_instance_valid(instance) and not instance.is_queued_for_deletion()),
				"More than one instance of Level exists."
				)
		instance = value

## Static instance, we should only have one Level in the scene tree at any time.
## This method uses an assertion and should be used when you don't expect to handle a null value.
static func get_instance() -> Level:
	assert(instance)
	return instance

static func get_base_tile_map_layer() -> TileMapLayer:
	assert(instance)
	assert(instance.base_tile_map_layer)
	return instance.base_tile_map_layer

static func get_hud() -> LevelHUD:
	var _hud = get_instance().hud
	assert(_hud != null and is_instance_valid(_hud))
	return _hud

## Returns all directors in the level scene in play order.
static func get_directors() -> Array[Director]:
	return get_instance().directors

## Returns the director whose turn it currently is.
static func get_current_director() -> Director:
	var director = get_instance().directors[instance.current_director_idx]
	assert(director and is_instance_valid(director), "Invalid current director")
	return director

## Returns all actors from the director whose turn it currently is.
static func get_current_directors_actors() -> Array[Actor]:
	return get_current_director().actors

## Returns all actors from all directors in the level.
static func get_all_actors_in_play_order() -> Array[Actor]:
	var actors: Array[Actor] = []
	if not instance:
		push_error("Can't get actors--no active level instance!")
	else:
		for dir in instance.directors:
			actors.append_array(dir.actors)
	return actors

## Returns an Actor if there is one at the given coordinates, otherwise returns Null.
static func get_actor_at(coords: Vector2i) -> Actor:
	for actor in get_all_actors_in_play_order():
		if actor.current_tile_coords == coords:
			return actor
	return null

##Returns actor from the relative pos of another actor
static func get_actor_at_relative_pos(actor: Actor,coords: Vector2i) -> Actor:
	var global_coords: Vector2i = actor.current_tile_coords + coords
	var result: Actor = get_actor_at(global_coords)
	print("get actors at relative pos: %s",result)
	return result

static func get_all_pick_ups()-> Array[PickUp]:
	return instance.pick_up_manager.pick_ups

static func get_pick_up_at(coords: Vector2i) -> PickUp:
	for pick_up in get_all_pick_ups():
		if pick_up.current_tile_coords == coords:
			return pick_up
	return null
	
## Used by Actors to reposition themselves at the start of the game
## to the pseudo-randomized location.
static func get_starting_coord(original: Vector2i) -> Vector2i:
	var inst = get_instance()
	if not inst.use_randomized_rotation_and_mirror:
		return original
	else:
		return Facing.rotate_hex(
			inst._level_start_facing,
			Facing.mirror_cell(original) if inst._level_start_mirror else original
			)
			
## Used by Actors to translate their facing direction at the start of the game.
static func get_starting_facing(original: Facing.Cardinal) -> Facing.Cardinal:
	var inst = get_instance()
	if not inst.use_randomized_rotation_and_mirror:
		return original
	else:
		if inst._level_start_mirror:
			return Facing.get_combined(Facing.mirror_facing(original), inst._level_start_facing)
		else:
			return Facing.get_combined(original, inst._level_start_facing)

#endregion
#region Virtuals

func _enter_tree() -> void:
	instance = self

func _ready() -> void:
	p("Loaded, setting up game.")
	start_game.call_deferred()

func _exit_tree() -> void:
	## Disconnect the global node_removed signal so a torn-down Level can't receive
	## removal events for the next scene's nodes during teardown.
	if get_tree() and get_tree().node_removed.is_connected(_on_node_removed):
		get_tree().node_removed.disconnect(_on_node_removed)
	if instance == self:
		instance = null

#endregion
#region Startup & Turn Progression

func start_game() -> void:
	assert(hud)
	assert(base_tile_map_layer)
	assert(tile_interactor)
	tile_interactor.set_tilemap(base_tile_map_layer)
	TargetFinder.setup(base_tile_map_layer)

	## Replace placeholders with chosen starting class
	for child in %Directors.get_children(): ## Maybe not very efficient
		if child is PlayerInsertPlaceholder:
			child.replace()

	get_tree().node_removed.connect(_on_node_removed)

	## Find and connect signals
	for child in %Directors.get_children():
		if child is Director:
			directors.append(child)
			if child is Player:
				child.setup(base_tile_map_layer, tile_interactor)
			elif child is AIDirector:
				child.setup(base_tile_map_layer)

	pick_up_manager.setup(base_tile_map_layer)

	var overlaps: String = _get_overlap_description()
	assert(overlaps.is_empty(), "Actors overlap: %s" % overlaps)

	playtime_counter_running = true
	next_turn()

## Returns a description of any actors sharing the same tile, or empty string if none overlap.
func _get_overlap_description() -> String:
	var tile_actors: Dictionary = {} # Vector2i -> Array[Actor]
	for actor in get_all_actors_in_play_order():
		var coords: Vector2i = actor.current_tile_coords
		if not tile_actors.has(coords):
			tile_actors[coords] = []
		tile_actors[coords].append(actor)

	var parts: PackedStringArray = []
	for coords in tile_actors:
		if tile_actors[coords].size() > 1:
			var names := (tile_actors[coords] as Array).map(func(a): return a.name)
			parts.append("%s at %s" % [names, coords])
	return ", ".join(parts)


func next_turn():
	turn_count += 1
	p("Starting turn %d" % turn_count)

	assert((directors.size() > 0))

	## All directors go each turn. The order is:
	## Enemies in order execute queued actions.
	## Enemies queue their actions for next turn.
	## Player is given control, they take time to examine the field and make their moves immediately.
	## Turn ends, cycles.
	for director in directors:
		waiting_to_finish.append(director)

	current_director_idx = -1
	_next_directors_turn()

func _next_directors_turn():
	if (current_director_idx + 1) >= directors.size():
		current_director_idx = 0
	else:
		current_director_idx += 1

	var director = directors[current_director_idx]
	assert(is_instance_valid(director))
	director.turn_taken.connect(_on_turn_taken, CONNECT_ONE_SHOT)
	director.take_turn.call_deferred()
	current_director_changed.emit(director)

func _on_turn_taken(director: Director) -> void:
	waiting_to_finish.erase(director)
	if waiting_to_finish.is_empty():
		next_turn()
	else:
		_next_directors_turn()

func pause_game(paused: bool) -> void:
	playtime_counter_running = not paused
	get_tree().paused = paused
	if paused && pause_menu:
		pause_menu.show()

#endregion
#region Objective Monitoring

func check_objectives() -> void:
	if is_complete: return
	p("Checking game objectives")
	await get_tree().process_frame
	if not _is_alive(): return  ## Bail if this Level was torn down during the awaited frame.

	if check_win_condition() == true:
		p("Win")
		is_complete = true
		_record_playtime()
		
		## Save
		save_persistent_actors_data()
		Main.register_level_progressed()

		continue_menu.show()

	elif check_lose_condition() == true:
		p("Lose")
		is_complete = true
		_record_playtime()
		
		retry_menu.show() #launch retry menu

func check_win_condition() -> bool:
	var dirs: Array[Director] = get_directors()
	for dir in dirs:
		if dir is AIDirector:
			if dir.actors.is_empty(): # check for living enemies
				return true
	return false #enemies were found

func check_lose_condition() -> bool:
	#check if player actors array is not emptpy if it is return false if able to process through all return true
	var dirs: Array[Director] = get_directors()
	for dir in dirs:
		if dir is Player:
			if !dir.actors.is_empty(): #if there is a player the game continues
				return false
	return true # no player actors found game lost

## True iff this Level is still the active instance and inside the tree. Used to short-circuit
## callbacks that may resume after _exit_tree (e.g. anything past an `await`).
func _is_alive() -> bool:
	return instance == self and is_inside_tree()

func _on_node_removed(node):
	if not _is_alive(): return
	if node is Actor:
		check_objectives()

#endregion
#region Metrics

var _play_started_time: float = 0.0
var total_play_time: float = 0.0
var playtime_counter_running: bool = false:
	set(value):
		if playtime_counter_running && value == false:
			_apply_elapsed_play_time()
			_play_started_time = 0.0

		elif not playtime_counter_running && value == true:
			_play_started_time = Time.get_ticks_msec()

		playtime_counter_running = value

func _apply_elapsed_play_time():
	total_play_time += (Time.get_ticks_msec() - _play_started_time) / 1000.0

func _record_playtime() -> void:
	## Record and save the final play time
	playtime_counter_running = false
	PlayerData.this.combat_playtime += total_play_time

#endregion
#region Other Gameplay Functionality

## Called by an Actor when it moves tiles. TODO Used for reactions...
func on_actor_moved(actor: Actor) -> void:
	for node: TileWatcher in get_tree().get_nodes_in_group(TileWatcher.GROUP_NAME):
		await node.on_actor_moved(actor)

## Save functionality for actor data
func save_persistent_actors_data() -> void:
	for actor in get_all_actors_in_play_order():
		actor.push_persistent_data()
	# Save player-director-level data (stash) onto the main actor's persistent record
	for director in get_directors():
		if director is Player:
			var main_actor: Actor = director.actors.front()
			if main_actor and main_actor.persistent_data_key and main_actor.persistent_actor_data:
				## Shallow duplicate — Action templates have no per-card runtime state today.
				## If Action ever gains mutable per-card state, switch to a deep copy or capture via to_dict here.
				main_actor.persistent_actor_data.stash = director.stash.duplicate()
				PlayerData.set_actor_data(main_actor.persistent_data_key, main_actor.persistent_actor_data)
				

## Triggers a random oneliner speech bubble to appear.
func trigger_speech_bubbles() -> void:
	if randf() > 0.5:
		var oneliners = get_tree().get_nodes_in_group(OneLiners.GROUP_NAME)
		if oneliners.size() > 1:
			for n in randi_range(0, oneliners.size()-1):
				var inst = oneliners.pick_random() as OneLiners
				inst.display_random_oneliner()
				oneliners.erase(inst)

## Same as above but it prepends a random phrase depending on the context [param positive].
func trigger_response_speech_bubbles(positive: bool) -> void:
	#if randf() > 0.5:
	var oneliners = get_tree().get_nodes_in_group(OneLiners.GROUP_NAME)
	if oneliners.size() > 1:
		for n in randi_range(0, oneliners.size()-1):
			var inst = oneliners.pick_random() as OneLiners
			inst.display_response_oneliner(positive)
			oneliners.erase(inst)

#endregion
