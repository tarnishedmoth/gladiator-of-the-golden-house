class_name Player extends Director

const HOLD_TIME_TO_END_TURN_EARLY: float = 2.5
const STICKY_TILE_SELECT: bool = false
const DESELECT_ON_REPEAT: bool = true

var tile_map: TileMapLayer
var tile_interactor: TileInteractor
var latest_tile_coords: Vector2i = Vector2i.ZERO
var selected_tile ## Null or Vector2i coords
var _last_selected_tile

func setup(tilemap: TileMapLayer, interactor: TileInteractor) -> void:
	self.tile_map = tilemap
	self.tile_interactor = interactor
	if not interactor.tile_changed.is_connected(_on_interactor_tile_changed):
		interactor.tile_changed.connect(_on_interactor_tile_changed)
	
	clear_and_repopulate_actors_from_children()
	for actor in actors:
		actor.setup(self, tile_map)
	
	if VERBOSE: p("Setup done.")
	

func _on_turn_started():
	if VERBOSE: p("Player turn started")
	pass
	
var _end_turn_with_available_moves: Tween
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"select_tile"):
		if not tile_interactor:
			push_warning("Tile interactor not valid.")
		else:
			## Check if clicked on a tile
			var tile
			if STICKY_TILE_SELECT:
				tile = tile_interactor.get_current_tile_coords()
			else:
				tile = tile_interactor.get_tile_coords_under_interactor()
				
			if DESELECT_ON_REPEAT && tile == _last_selected_tile:
				tile = null ## Deselect
			
			## We have our tile coordinates
			selected_tile = tile
			
			## Check for actor on tile
			var actor_on_tile: Actor = Level.get_actor_at(selected_tile)
				
			if VERBOSE:
				p("Selected tile: %s" % selected_tile)
				if actor_on_tile:
					p("Tile coords occupied by actor %s" % actor_on_tile)
			
			## Behavior using this data
			if is_active:
				## It's our turn
				pass
			else:
				## It's not our turn
				pass
				
			_last_selected_tile = selected_tile
	
	if event.is_action_pressed(&"open_pause_menu"):
			get_tree().quit() ## FIXME
			pass
	
	if is_active:
		if event.is_action_pressed(&"end_turn"):
			#if still have available moves:
				#_end_turn_with_available_moves = create_tween()
				#_end_turn_with_available_moves.tween_interval(HOLD_TIME_TO_END_TURN_EARLY)
				#_end_turn_with_available_moves.tween_callback(end_turn)
			#else:
			end_turn()
		elif event.is_action_released(&"end_turn"):
			if _end_turn_with_available_moves:
				if _end_turn_with_available_moves.is_valid():
					_end_turn_with_available_moves.kill()
		
	else:
		pass

func _on_interactor_tile_changed(new_coords: Vector2i) -> void:
	latest_tile_coords = new_coords
