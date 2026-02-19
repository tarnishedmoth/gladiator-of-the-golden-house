class_name Player extends Director

const HOLD_TIME_TO_END_TURN_EARLY: float = 2.5
const STICKY_TILE_SELECT: bool = false
const DESELECT_ON_REPEAT: bool = true

var tile_map: TileMapLayer
var tile_interactor: TileInteractor
var latest_tile_coords: Vector2i = Vector2i.ZERO
var selected_tile ## Null or Vector2i coords
var _last_selected_tile

var hud: LevelHUD

## Actions
@export var hand_size: int = 5 ## Number of actions that will be drawn at the start of the turn
@export var starting_actions_deck: Array[Action] ## The entirety of actions available to be drawn.
var draw_deck: Array[Action] ## The entirety of actions available to be drawn.
var discard_deck: Array[Action] ## When [member draw_deck] runs empty, these are re-shuffled for play.
var exhausted_deck: Array[Action] ## Are removed from play for the rest of this match.
var actions_in_hand: Array[Action] ## Action cards that the player currently has on screen to choose from.
var current_held_action: Action ## The action to be previewed or played.

var selected_actor: Actor

func _ready():
	pass

func setup(tilemap: TileMapLayer, interactor: TileInteractor) -> void:
	self.hud = Level.get_instance().hud
	self.tile_map = tilemap
	self.tile_interactor = interactor
	if not interactor.tile_changed.is_connected(_on_interactor_tile_changed):
		interactor.tile_changed.connect(_on_interactor_tile_changed)

	clear_and_repopulate_actors_from_children()
	for actor in actors:
		actor.setup(self, tile_map)
		
	draw_deck = starting_actions_deck.duplicate()
	if VERBOSE: p("Setup done.")


func _on_turn_started():
	if VERBOSE: p("Player turn started")
	
	for actor in actors:
		actor.process_on_turn_start_status_effects()
		
	select_actor(actors.front())
	draw_hand()
	
	## TESTING remove me
	hold_action(actions_in_hand.front()) ## TESTING remove me
	
	
func _end_turn() -> void:
	discard_hand()
	end_turn()

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

			_on_click_on_tile(tile)

	if event.is_action_pressed(&"open_pause_menu"):
			get_tree().quit() ## FIXME
			pass

	if is_active:
		if event.is_action_pressed(&"end_turn"):
			#if still have available moves:
				#_end_turn_with_available_moves = create_tween()
				#_end_turn_with_available_moves.tween_interval(HOLD_TIME_TO_END_TURN_EARLY)
				#_end_turn_with_available_moves.tween_callback(_end_turn)
			#else:
			_end_turn()
		elif event.is_action_released(&"end_turn"):
			if _end_turn_with_available_moves:
				if _end_turn_with_available_moves.is_valid():
					_end_turn_with_available_moves.kill()

	else:
		pass

func _on_interactor_tile_changed(new_coords: Vector2i) -> void:
	latest_tile_coords = new_coords

func _on_click_on_tile(tile_coords) -> void:
	if DESELECT_ON_REPEAT && tile_coords == _last_selected_tile:
		tile_coords = null ## Deselect

	## We have our tile coordinates
	selected_tile = tile_coords
	if VERBOSE:
		p("Selected tile: %s" % selected_tile)

	if selected_tile != null: ## Null check
		## Get TileData (just for UI for now)
		#var tile_data: TileData = tile_interactor.get_tile_data(selected_tile) ## TODO this could handle land type

		## Check for actor on tile
		var actor_on_tile: Actor = Level.get_actor_at(selected_tile)
		if VERBOSE && actor_on_tile:
			p("Tile coords occupied by actor %s" % actor_on_tile)

		## Behavior using this data
		if is_active:
			## It's our turn
			if current_held_action:
				if selected_tile in selected_actor.get_action_target_cells(current_held_action):
					## Valid play placement
					if VERBOSE: p("Playing %s on %s" % [current_held_action.ui_title, selected_actor])
					play_held_action()
				else:
					## Invalid play placement
					if VERBOSE: p("Can't play that Action here.")
					
			## Tested working, but needs to be separated--presently this control scheme does not make sense.
			## Thinking that changing selected actor should require pressing a button to highlight your available actors
			#elif actor_on_tile and actor_on_tile in actors:
				#if actor_on_tile != selected_actor:
					#if VERBOSE: p("Selecting team actor %s" % actor_on_tile)
					#select_actor(actor_on_tile)
				#else:
					#if VERBOSE: p("Deselected team actor %s" % selected_actor)
					#deselect_actor()

		else:
			## It's not our turn
			pass

		hud.populate_hover_panel(selected_tile, actor_on_tile)
		hud.show_hover_panel(true)
	else:
		hud.show_hover_panel(false)

	_last_selected_tile = selected_tile
	
func _on_click_to_play_action() -> void:
	TargetFinder.clear_target_highlights()
	play_held_action()

#region Actions / Deck Logic
## Used to preview actions.
func hold_action(action: Action):
	current_held_action = action
	if current_held_action:
		TargetFinder.highlight_targets(selected_actor.get_action_target_cells(current_held_action))
	else:
		TargetFinder.clear_target_highlights()
	SignalBus.player_held_action_changed.emit(current_held_action)

func unhold_action(): hold_action(null)

func draw_hand(draw_count: int = hand_size):
	for card in draw_count:
		draw_next_card()
	
func draw_next_card():
	if draw_deck.is_empty():
		discard_deck.shuffle()
		draw_deck.append_array(discard_deck)
		if VERBOSE: p("Reshuffled %d cards in discard deck into draw deck." % discard_deck.size())
		discard_deck.clear()
	
	var drawn: Action = draw_deck.pop_front()
	actions_in_hand.push_back(drawn)
	
	if VERBOSE: p("Drew action: %s" % drawn.ui_title)
	SignalBus.player_hand_changed.emit(actions_in_hand)
	
func discard(card):
	discard_deck.push_back(card) ## Brain says push_front, but arrays can only be appended so lets just know that this deck is "upside down"
	actions_in_hand.erase(card)
	SignalBus.player_hand_changed.emit(actions_in_hand)
	
func discard_hand():
	unhold_action()
	discard_deck.append_array(actions_in_hand)
	actions_in_hand.clear()
	SignalBus.player_hand_changed.emit(actions_in_hand)
	
func play_held_action():
	selected_actor.run_action(current_held_action)
	unhold_action()
	discard(current_held_action)

#endregion

func select_actor(actor: Actor) -> void:
	if actor == null:
		selected_actor = null
		if VERBOSE: p("Deselected actor")
	else:
		assert(actor in actors)
		selected_actor = actor
		if VERBOSE: p("Selected actor %s" % selected_actor)
	SignalBus.player_selected_actor_changed.emit(selected_actor)

func deselect_actor() -> void: select_actor(null)
