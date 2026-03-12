class_name Player extends Director

const HOLD_TIME_TO_END_TURN_EARLY: float = 1.5
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
@export var always_available_deck: Array[Action] ## These actions are drawn every turn and don't move to the discard pile.
@export var stances: Array[Stance] ## Branches of action sets (decks) that are equipped in gameplay.
var draw_deck: Array[Action] ## The entirety of actions available to be drawn.
var discard_deck: Array[Action] ## When [member draw_deck] runs empty, these are re-shuffled for play.
var exhausted_deck: Array[Action] ## Are removed from play for the rest of this match.
var actions_in_hand: Array[Action] ## Action cards that the player currently has on screen to choose from.
var current_held_action: Action ## The action to be previewed or played.

var selected_actor: Actor:
	set(v):
		selected_actor = v
		update_hud_actions_energy_check()

const SELECTED_TILE_VISUAL_SCENE = preload("uid://b5dsq2oi2kchw")
var _selected_tile_visual: Node2D
func set_selected_tile_visual(to_show: bool) -> void:
	if not to_show:
		if _selected_tile_visual:
			if _selected_tile_visual.visible:
				_selected_tile_visual.hide()
	else:
		if not _selected_tile_visual:
			_selected_tile_visual = SELECTED_TILE_VISUAL_SCENE.instantiate()
			add_child(_selected_tile_visual)
		_selected_tile_visual.show()
		_selected_tile_visual.global_position = tile_map.to_global(tile_map.map_to_local(selected_tile))


func _ready():
	pass

func setup(tilemap: TileMapLayer, interactor: TileInteractor) -> void:
	self.hud = Level.get_hud()
	self.tile_map = tilemap
	self.tile_interactor = interactor
	if not interactor.tile_changed.is_connected(_on_interactor_tile_changed):
		interactor.tile_changed.connect(_on_interactor_tile_changed)

	clear_and_repopulate_actors_from_children()
	for actor in actors:
		actor.setup(self, tile_map)
		
	draw_deck = starting_actions_deck.duplicate()
	## HACK remove me TESTING
	for stance in stances:
		draw_deck.append_array(stance.actions)
		
	draw_deck.shuffle()
	if VERBOSE: p("Setup done.")


func _on_turn_started():
	if VERBOSE: p("Player turn started")
	
	select_actor(actors.front())
	draw_hand()
	#hold_action(actions_in_hand.front())
	
	
func _end_turn() -> void:
	if is_active:
		discard_hand()
		end_turn()

var _end_turn_with_available_moves: Tween
func user_pressed_end_turn_button() -> bool: ## Returns true if turn is ending immediately, false if user must hold.
	var player_has_remaining_actions: bool = \
	(not actions_in_hand.is_empty()) \
	and actors_have_remaining_energy() \
	and actors_have_usable_actions(actions_in_hand)
	
	if player_has_remaining_actions:
		_end_turn_with_available_moves = create_tween()
		_end_turn_with_available_moves.tween_interval(HOLD_TIME_TO_END_TURN_EARLY)
		_end_turn_with_available_moves.tween_callback(_end_turn)
		return false
	else:
		_end_turn()
		return true
		
func user_released_end_turn_button() -> void:
	if _end_turn_with_available_moves:
		if _end_turn_with_available_moves.is_valid():
			_end_turn_with_available_moves.kill()

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
		if event.is_action_pressed(&"end_turn"): ## Keybind. See HUD.gd for clickable button
			user_pressed_end_turn_button()
		elif event.is_action_released(&"end_turn"):
			user_released_end_turn_button()

	else:
		pass

func _on_interactor_tile_changed(new_coords: Vector2i) -> void:
	latest_tile_coords = new_coords

func _on_click_on_tile(tile_coords) -> void:
	## We have our tile coordinates
	selected_tile = tile_coords
	if VERBOSE:
		p("Selected tile: %s" % selected_tile)

	if selected_tile != null: ## Null check
		#var tile_data: TileData = tile_interactor.get_tile_data(selected_tile) ## TODO this could handle land type

		## Check for actor on tile (testing)
		#var actor_on_tile: Actor = Level.get_actor_at(selected_tile)
		#if VERBOSE && actor_on_tile:
			#p("Tile coords occupied by actor %s" % actor_on_tile)

		## Behavior using this data
		if is_active:
			## It's our turn
			if current_held_action:
				if selected_tile in selected_actor.get_action_target_cells(current_held_action):
					## Valid play placement
					if VERBOSE: p("Playing %s at %s on %s" % [current_held_action.ui_title, selected_tile, selected_actor])
					_on_click_to_play_action(selected_tile)
				else:
					## Invalid play placement
					if VERBOSE: p("Can't play that Action here.")
					
			else:
				if DESELECT_ON_REPEAT && tile_coords == _last_selected_tile:
					selected_tile = null ## Deselect
					p("Same tile selected as last click--Deselecting.")
					set_selected_tile_visual(false)
					hud.show_hover_panel(false)
				else:
					hud.populate_hover_panel(selected_tile, Level.get_actor_at(selected_tile))
					hud.show_hover_panel(true)
					set_selected_tile_visual(true)
				
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

	else:
		set_selected_tile_visual(false)
		hud.show_hover_panel(false)

	_last_selected_tile = selected_tile
	
func _on_click_to_play_action(target_coords: Vector2i) -> void:
	play_held_action_at(target_coords)

#region Actions / Deck Logic
## Used to preview actions.
func hold_action(action: Action):
	if (action != null) and (current_held_action == action):
		unhold_action()
		return
	else:
		current_held_action = action
		
	TargetFinder.clear_target_highlights()
	if current_held_action:
		TargetFinder.highlight_targets(selected_actor.get_action_target_cells(current_held_action))
		
	if VERBOSE:
		p("Current held action: %s" % (current_held_action.ui_title if current_held_action else "empty"))

func unhold_action(): hold_action(null)

func draw_hand(draw_count: int = hand_size):
	for card in always_available_deck:
		if card not in actions_in_hand:
			actions_in_hand.push_front(card)
	
	for card in draw_count:
		_draw_next_card()
	hud.populate_actions_list(actions_in_hand) ## Update HUD
	update_hud_actions_energy_check()
	
func discard_hand():
	unhold_action()
	#discard_deck.append_array(actions_in_hand)
	for card in actions_in_hand:
		if not card in always_available_deck:
			discard_deck.append(card)
	actions_in_hand.clear()
	
	hud.populate_actions_list([]) ## Update HUD
	update_hud_actions_energy_check()
	
	
func _draw_next_card():
	if draw_deck.is_empty():
		discard_deck.shuffle()
		draw_deck.append_array(discard_deck)
		if VERBOSE: p("Reshuffled %d cards in discard deck into draw deck." % discard_deck.size())
		discard_deck.clear()
	
	var drawn: Action = draw_deck.pop_front()
	actions_in_hand.push_back(drawn)
	
	if VERBOSE: p("Drew action: %s" % drawn.ui_title)
	
func _discard(card):
	if not card in always_available_deck:
		discard_deck.push_back(card) ## Brain says push_front, but arrays can only be appended so lets just know that this deck is "upside down"
	actions_in_hand.erase(card)
	
func play_held_action_at(coords: Vector2i):
	if current_held_action.can_player_enter(selected_actor):
		selected_actor.remove_energy(current_held_action.energy_cost)
		current_held_action.set_target(coords)
		selected_actor.run_action(current_held_action)
		_discard(current_held_action)
		unhold_action()
		
		hud.populate_actions_list(actions_in_hand)
		update_hud_actions_energy_check()

#endregion

func select_actor(actor: Actor) -> void:
	if actor == null:
		selected_actor = null
		if VERBOSE: p("Deselected actor")
	else:
		assert(actor in actors)
		selected_actor = actor
		if VERBOSE: p("Selected actor %s" % selected_actor)

func deselect_actor() -> void: select_actor(null)

func update_hud_actions_energy_check() -> void:
	hud.actions_panel.action_buttons_energy_check_set_disabled(
		selected_actor.energy if selected_actor else 0
		)


#func get_all_cards(and_exhausted: bool = false) -> Array[Action]:
	#return actions_in_hand + discard_deck + exhausted_deck if and_exhausted else []
#
#func change_stance(new_stance: Stance) -> void:
	### Remove all cards from the old stance, add current stance cards.
	### And also somehow don't mess up the card stack (shuffle).
	#if not new_stance == stance:
		#for action in get_all_cards():
			#if action not in always_available_deck:
				#action.free() ## TODO I dont think this works
				### TODO etc
