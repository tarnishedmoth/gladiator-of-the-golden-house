class_name Level extends Node2D

## Handles basic setup, turn events, and exit of the play scene.
const VERBOSE: bool = true
func p(args):
	print_rich("[bgcolor=red][color=white]", "Level: ", args)

## Static instance, we should only have one Level in the scene tree at any time.
static var instance: Level:
	set(value):
		if instance != null:
			if is_instance_valid(instance):
				if not instance.is_queued_for_deletion():
					push_warning("More than one instance of Level exists.")
		instance = value

## Static instance, we should only have one Level in the scene tree at any time.
## This method uses an assertion and should be used when you don't expect to handle
## a null value.
static func get_instance() -> Level:
	assert(instance)
	return instance
	
static func get_all_actors_in_play_order() -> Array[Actor]:
	var actors: Array[Actor] = []
	if not instance:
		push_error("Can't get actors--no active level instance!")
	else:
		for dir in instance.directors:
			actors.append_array(dir.actors)
	return actors
	
@export var base_tile_map_layer: TileMapLayer ## This is used for detecting mouse input.
@export var tile_interactor: TileInteractor ## This is used for detecting mouse input.
	
var turn_count: int = 0

var directors: Array[Director] = []
var current_director: int = -1
var waiting_to_finish: Array[Director] = []


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
	total_play_time += Time.get_ticks_msec() - _play_started_time
	
func _enter_tree() -> void:
	instance = self

func _ready() -> void:
	if VERBOSE: p("Loaded, setting up game.")
	start_game.call_deferred()
	
func start_game() -> void:
	assert(base_tile_map_layer)
	assert(tile_interactor)
	tile_interactor.set_tilemap(base_tile_map_layer)
	
	## Find and connect signals
	for child in %Directors.get_children():
		if child is Director:
			directors.append(child)
			if child is Player:
				child.setup(base_tile_map_layer, tile_interactor)
			elif child is AIDirector:
				child.setup(base_tile_map_layer)
	
	playtime_counter_running = true
	next_turn()
	
	
func next_turn():
	turn_count += 1
	if VERBOSE: p("Starting turn %d" % turn_count)
	
	assert((directors.size() > 0))
	
	## All directors go each turn. The order is:
	## Enemies in order execute queued actions.
	## Enemies queue their actions for next turn.
	## Player is given control, they take time to examine the field and make their moves immediately.
	## Turn ends, cycles.
	for director in directors:
		waiting_to_finish.append(director)
	
	await _ai_turn()
	_player_turn()
	
func _ai_turn():
	for director in directors:
		if director is AIDirector:
			director.take_turn.call_deferred()
			await director.turn_taken ## Awaits let us wait for animations to play out
			_on_turn_taken(director)
			
func _player_turn():
	var player_idx: int = directors.find_custom(func(v): return (v is Player))
	assert(player_idx > -1)
	var player = directors[player_idx]
	player.turn_taken.connect(_on_turn_taken, CONNECT_ONE_SHOT)
	player.take_turn.call_deferred()
	
func _on_turn_taken(director: Director) -> void:
	waiting_to_finish.erase(director)
	if waiting_to_finish.is_empty():
		next_turn()

func show_pause_menu() -> void:
	playtime_counter_running = false
	pass
