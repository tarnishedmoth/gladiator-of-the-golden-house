class_name Player extends Director

const HOLD_TIME_TO_END_TURN_EARLY: float = 1.5
const STICKY_TILE_SELECT: bool = false
const DESELECT_ON_REPEAT: bool = true
const SELECT_FACING_INDICATOR = preload("uid://dtgl2ndfa7uub")
var select_facing_is_visible: bool:
	set(v):
		select_facing_is_visible = v
		if tile_interactor:
			## Hide the tile highlight when the widget is showing
			tile_interactor.show_highlight = not select_facing_is_visible


var tile_map: TileMapLayer
var tile_interactor: TileInteractor
var _last_hovered_tile: Vector2i = Vector2i.ZERO ## See also [method TileInteractor.get_current_tile_coords()].
var selected_tile ## Null or Vector2i coords
var _last_selected_tile

var hud: LevelHUD

## Actions
@export var hand_size: int = 5 ## Number of actions that will be drawn at the start of the turn
@export var starting_actions_deck: Array[Action] ## The entirety of actions available to be drawn.
@export var always_available_deck: Array[Action] ## These actions are drawn every turn and don't move to the discard pile.
@export var stances: Array[Stance] ## Branches of action sets (decks) that are equipped in gameplay. The first entry will be started with.
var current_stance: Stance
#var current_stance_idx: int:
	#set(v):
		#current_stance_idx = clampi(v, 0, stances.size()-1)

var draw_deck: Array[Action] ## The entirety of actions available to be drawn.
var discard_deck: Array[Action] ## When [member draw_deck] runs empty, these are re-shuffled for play.
var exhausted_deck: Array[Action] ## Are removed from play for the rest of this match.
var actions_in_hand: Array[Action] ## Action cards that the player currently has on screen to choose from.
var current_held_action: Action ## The action to be previewed or played.
var stash: Array[Action] ## Persistent bonus cards, consumed on use.

var selected_actor: Actor:
	set(v):
		selected_actor = v
		update_hud_actions_disabled_check()

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
	if not stances.is_empty():
		change_stance(stances.front().pickme_action.stance_uid)
	draw_deck.shuffle()

	var main_actor: Actor = actors.front()
	if main_actor and main_actor.persistent_data_key:
		var actor_data = PlayerData.get_actor_data(main_actor.persistent_data_key)
		if actor_data and not actor_data.stash.is_empty():
			stash = actor_data.stash.duplicate()
			if VERBOSE: p("Loaded %d stashed cards." % stash.size())

	if VERBOSE: p("Setup done.")


func _on_turn_started():
	if VERBOSE: p("Player turn started")

	select_actor(actors.front())
	draw_hand()
	#hold_action(actions_in_hand.front())


func _end_turn() -> void:
	if is_active:
		discard_hand()
		deselect_tile()
		end_turn()

var _end_turn_with_available_moves: Tween
func user_pressed_end_turn_button() -> bool: ## Returns true if turn is ending immediately, false if user must hold.
	var all_available_actions: Array[Action] = actions_in_hand + stash
	var player_has_remaining_actions: bool = \
	(not all_available_actions.is_empty()) \
	and actors_have_remaining_energy() \
	and actors_have_usable_actions(all_available_actions)

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
		Level.get_instance().pause_game(true)

	if is_active:
		if event.is_action_pressed(&"end_turn"): ## Keybind. See HUD.gd for clickable button
			user_pressed_end_turn_button()
		elif event.is_action_released(&"end_turn"):
			user_released_end_turn_button()

	else:
		pass

var _previous_hovered_actor: Actor ## For health
func _on_interactor_tile_changed(new_coords: Vector2i) -> void:
	_last_hovered_tile = new_coords
	
	if _previous_hovered_actor:
		_previous_hovered_actor.on_unhovered()
	
	var actor: Actor = Level.get_actor_at(new_coords)
	if actor:
		actor.on_hovered()
		_previous_hovered_actor = actor
	
	if not current_held_action:
		update_npc_action_preview()
	elif not _currently_playing_action: ## Prevent highlights from appearing when selecting facing direction/animations playing
		if current_held_action.get(&"split_choice"):
			## Check which side of the forward axis we're on, to decide to mirror
			var relative_coord: Vector2i = Facing.unrotate_hex(selected_actor.facing, new_coords - selected_actor.current_tile_coords)
			var mirror: bool = signi(relative_coord.x) < 0
			#if VERBOSE: p("Split Choice -- rel: %s, mirroring: %s" % [relative_coord, mirror])
			if mirror != current_held_action.run_mirrored:
				current_held_action.run_mirrored = mirror
		rerender_held_action_targets()
		
	#elif is_active and current_held_action and selected_actor:
		## TODO not functional -- see Action.ImplicatedTiles...
		#tile_interactor.render_held_action_projection(self)
		#pass
		

func _on_click_on_tile(tile_coords) -> void:
	if VERBOSE:
		p("Clicked tile: %s" % tile_coords)

	if tile_coords != null: ## Null check
		selected_tile = tile_coords
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
					unhold_action()

			else:
				if DESELECT_ON_REPEAT && tile_coords == _last_selected_tile:

					p("Same tile selected as last click--Deselecting.")
					deselect_tile()
					
				else:
					hud.populate_hover_panel(selected_tile, Level.get_actor_at(selected_tile))
					hud.show_hover_panel(true)
					set_selected_tile_visual(true)

			
			## --CHANGING SELECTED ACTOR
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

func deselect_tile() -> void:
	selected_tile = null
	set_selected_tile_visual(false)
	hud.show_hover_panel(false)

func _on_click_to_play_action(target_coords: Vector2i) -> void:
	TargetFinder.clear_all_highlights()
	deselect_tile()
	TargetFinder.highlight_target(target_coords, Action.get_action_color(current_held_action), selected_actor) ## Keep our selection highlighted
	play_held_action_at(target_coords)

var _self_action_preview_showing: bool = false
func rerender_held_action_targets() -> void: ## Clear all highlighted tiles and re-render
	if _self_action_preview_showing:
		#TargetFinder.clear_target_highlights(selected_actor) ## HACK
		selected_actor.hide_preview_for_actions()
	
	if current_held_action:
		update_npc_action_preview() ## clears/resets any existing previews
		selected_actor.render_preview_for_action(current_held_action, _last_hovered_tile)
		_self_action_preview_showing = true

#region Actions / Deck Logic
## Used to preview actions.
func hold_action(action: Action):
	if (action != null) and (current_held_action == action):
		unhold_action()
		return
	else:
		current_held_action = action
	
	rerender_held_action_targets()
	if VERBOSE:
		p("Current held action: %s" % (current_held_action.ui_title if current_held_action else "empty"))

## Used to discard actions.
func unhold_action(): hold_action(null)

func draw_hand(draw_count: int = hand_size):
	for card in always_available_deck:
		if card not in actions_in_hand:
			if card is ActionChangeStance:
				push_error("Stance change cards are added procedurally from the Stances property.")
			else:
				actions_in_hand.push_front(card)
	
	for stance in stances:
		if stance != current_stance:
			assert(stance.pickme_action, "Stance needs a pickme action to be pickable.")
			actions_in_hand.push_back(stance.pickme_action)

	for card in draw_count:
		_draw_next_card()
	hud.populate_actions_list(actions_in_hand, selected_actor) ## Update HUD
	hud.populate_stash_list(stash, selected_actor)
	update_hud_actions_disabled_check()

func discard_hand():
	unhold_action()
	
	var to_erase: Array[Action] = actions_in_hand.duplicate()
	for card in to_erase: ## because you can't iterate over an array and erase elements, we copy the array first...
		_discard(card)

	hud.populate_actions_list([], selected_actor) ## Update HUD
	update_hud_actions_disabled_check()


func _draw_next_card():
	if draw_deck.is_empty():
		if not discard_deck.is_empty():
			discard_deck.shuffle()
			draw_deck.append_array(discard_deck)
			if VERBOSE: p("Reshuffled %d cards in discard deck into draw deck." % discard_deck.size())
			discard_deck.clear()
		else:
			push_error("Out of cards!!")
			return

	var drawn: Action = draw_deck.pop_front()
	actions_in_hand.push_back(drawn)

	if VERBOSE: p("Drew action: %s" % drawn.ui_title)

## Add this card to discard_deck and erase from actions_in_hand.
func _discard(card):
	if (not card in always_available_deck) && (not card is ActionChangeStance):
		discard_deck.push_back(card) ## Brain says push_front, but arrays can only be appended so lets just know that this deck is "upside down"
	actions_in_hand.erase(card)

func get_facing(place_indicator_pos):
	select_facing_is_visible = true
	
	var facing_indicator = SELECT_FACING_INDICATOR.instantiate()
	self.add_child(facing_indicator)
	facing_indicator.global_position = place_indicator_pos
	facing_indicator.show()
	
	var selected_facing_dir = await facing_indicator.facing_selected ## NOTICE AWAIT
	selected_actor.set_facing(selected_facing_dir)
	facing_indicator.queue_free()
	select_facing_is_visible = false

var _currently_playing_action: bool = false
func play_held_action_at(coords: Vector2i):
	if current_held_action.can_player_enter(selected_actor):
		_currently_playing_action = true
		
		hud.end_turn_button.hide()
		hud.end_turn_button.disabled = true
		hud.on_player_running_action(current_held_action) ## Action button list animations/dimming
		
		var position_for_facing
		if current_held_action.allow_facing_before:
			position_for_facing = selected_actor.global_position
			await get_facing(position_for_facing)
		
		selected_actor.remove_energy(current_held_action.energy_cost)
		current_held_action.set_target(coords)
		
		selected_actor.queue_action(current_held_action, true)
		await selected_actor.queued_actions_finished
		
		var is_from_stash: bool = current_held_action in stash
		if is_from_stash:
			remove_from_stash(current_held_action)
		else:
			if current_held_action.action_category == Action.ActionCategory.CONSUMABLE:
				remove_from_deck(current_held_action)
			else:
				_discard(current_held_action)
		
		if current_held_action.allow_facing_after:
			position_for_facing = selected_actor.global_position
			await get_facing(position_for_facing)
		
		_currently_playing_action = false
		unhold_action()
		hud.populate_actions_list(actions_in_hand, selected_actor)
		update_hud_actions_disabled_check()
		hud.end_turn_button.disabled = false
		hud.end_turn_button.show()

func add_to_deck(card: Action) -> void:
	if card == null:
		if VERBOSE: p("Card to add was null")
		return
	if VERBOSE: p("Adding card %s to deck." % card.ui_title)
	draw_deck.push_back(card)

func remove_from_deck(card: Action) -> void:
	if card == null:
		if VERBOSE: p("Card to remove was null")
		return
	if card in discard_deck:
		if VERBOSE: p("Removed card %s from deck." % card.ui_title)
		discard_deck.erase(card)
	if card in draw_deck:
		draw_deck.erase(card)
	if card in actions_in_hand:
		actions_in_hand.erase(card)

func add_to_stash(card: Action) -> void:
	if card == null:
		if VERBOSE: p("Card to stash was null")
		return
	card.action_category = Action.ActionCategory.CONSUMABLE
	stash.append(card)
	hud.populate_stash_list(stash, selected_actor)
	update_hud_actions_disabled_check()
	if VERBOSE: p("Stashed card: %s" % card.ui_title)

func remove_from_stash(card: Action) -> void:
	stash.erase(card)
	hud.populate_stash_list(stash, selected_actor)
	update_hud_actions_disabled_check()
	if VERBOSE: p("Removed stashed card: %s" % card.ui_title)
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

func update_hud_actions_disabled_check() -> void:
	hud.actions_panel.check_actions_disabled(selected_actor)
	hud.stash_panel.check_actions_disabled(selected_actor)


var _action_preview_showing: bool = false
## This method updates AIActor action previews.
## This method calls every [method AIActor.hide_preview_attack], then finds the
## actor on our mouse-hovered tile and calls [method AIActor.preview_ai_attack].
func update_npc_action_preview() -> void:
	if _action_preview_showing:
		for actor in Level.get_all_actors_in_play_order():
			if actor is AIActor:
				actor.hide_preview_for_actions()

	#check if there is an AI actor on selected tile needs their preview added
	if is_active:
		if(_last_hovered_tile != null and current_held_action == null): #prevents preview from being added when an action is being held
			var actor = Level.get_actor_at(_last_hovered_tile) as AIActor
			if actor != null:
				_action_preview_showing = true
				actor.preview_ai_attack()


func get_all_cards(and_exhausted: bool = false) -> Array[Action]:
	if and_exhausted:
		return actions_in_hand + discard_deck + exhausted_deck
	else:
		return actions_in_hand + discard_deck

var last_stance_status_key
## Arg is a UID
func change_stance(new_stance_uid) -> void:
	## Remove all cards from the old stance, add current stance cards.
	## And also somehow don't mess up the card stack (shuffle).
	
	var new_stance_path = ResourceUID.uid_to_path(new_stance_uid)
	if new_stance_path:
		var new_stance: Stance = ResourceLoader.load(new_stance_path)
		if not new_stance == current_stance:
			for actor in actors:
				actor.erase_keyed_statuses(last_stance_status_key)
			
			for card in get_all_cards():
				if card in current_stance.actions:
					remove_from_deck(card)
			
			current_stance = new_stance
			
			for card in new_stance.actions:
				add_to_deck(card)
				draw_deck.shuffle() ## NOTE we also are shuffling the deck when this is called.
