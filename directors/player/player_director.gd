class_name Player extends Director

const HOLD_TIME_TO_END_TURN_EARLY: float = 1.3
const REPLACE_STANCE_CARDS_IN_HAND: bool = true
const STICKY_TILE_SELECT: bool = false
const DESELECT_ON_REPEAT: bool = true

const SELECT_FACING_INDICATOR = preload("uid://dtgl2ndfa7uub")
var select_facing_is_visible: bool:
	set(v):
		select_facing_is_visible = v
		if tile_interactor:
			## Hide the tile highlight when the widget is showing
			tile_interactor.show_highlight = not select_facing_is_visible

const VERBOSE_CARDS: bool = true

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
		actor.is_active = true
	
	draw_deck = starting_actions_deck.duplicate()
	if VERBOSE_CARDS: p("Copied starting actions to draw deck.")
	
	if not stances.is_empty():
		change_stance(stances.front().pickme_action.stance_uid)
	draw_deck.shuffle()
	if VERBOSE_CARDS: p("Shuffled draw deck: %d cards." % draw_deck.size())

	var main_actor: Actor = actors.front()
	if main_actor and main_actor.persistent_data_key:
		var actor_data = PlayerData.get_actor_data(main_actor.persistent_data_key)
		if actor_data and not actor_data.stash.is_empty():
			stash = actor_data.stash.duplicate()
			if VERBOSE: p("Loaded %d stashed cards." % stash.size())

	if VERBOSE: p("Setup done.")


func take_turn() -> void:
	## the super() of this method calls the status effects which would modify this value so we must do this first.
	clear_addtl_energy_cost()
	super()

func _on_turn_started():
	if VERBOSE: p("Player turn started.")
	
	select_actor(actors.front()) ## HACK implement a way to select actors when there's a need for it
	draw_hand()
	#hold_action(actions_in_hand.front())


func _end_turn() -> void:
	if is_active:
		discard_hand()
		deselect_tile()
		deselect_actor()
		#TargetFinder.clear_all_highlights()
		clear_all_npc_action_previews()
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
func unhover_previous_actor() -> void:
	if _previous_hovered_actor:
		_previous_hovered_actor.on_unhovered()

func _on_interactor_tile_changed(new_coords: Vector2i) -> void:
	_last_hovered_tile = new_coords
	
	unhover_previous_actor()
	
	var actor: Actor = Level.get_actor_at(new_coords)
	if actor:
		actor.on_hovered()
		_previous_hovered_actor = actor
	
	if _currently_playing_action: ## Prevent highlights from appearing when selecting facing direction/animations playing
		return
	if not current_held_action:
		update_npc_action_preview()
	else: 
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
					hud.populate_hover_panel(selected_tile)
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
	play_held_action_at(target_coords)


func rerender_held_action_targets() -> void: ## Clear all highlighted tiles and re-render
	if not selected_actor: return
	selected_actor.hide_preview_for_actions()
	
	if current_held_action:
		update_npc_action_preview() ## clears/resets any existing previews
		selected_actor.render_preview_for_action(current_held_action, _last_hovered_tile)

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
	if VERBOSE_CARDS: p("Drawing hand...")
	Level.get_instance().play_cards_sfx()
	
	## Add all cards in always available deck
	for card in always_available_deck:
		if card in actions_in_hand:
			if VERBOSE_CARDS: p("Card %s already in hand, skipping..." % card)
		else:
			if card is ActionChangeStance:
				push_error("Stance change cards are added procedurally from the Stances property.")
			
			else:
				actions_in_hand.push_front(card)
				if VERBOSE_CARDS: p("Pushed always available %s to the front." % card)
	
	## Add the stance change action for each other stance.
	for stance in stances:
		if stance != current_stance:
			assert(stance.pickme_action, "Stance needs a pickme action to be pickable.")
			actions_in_hand.append(stance.pickme_action)
			if VERBOSE_CARDS: p("Appended stance change %s to the back." % stance.pickme_action)

	for card in draw_count:
		draw_next_card()
	
	for card in actions_in_hand:
		card.set_actor(selected_actor)
		
	refresh_hud_actions_and_stash()

func refresh_hud_actions_and_stash() -> void:
	hud.populate_actions_list(actions_in_hand, selected_actor) ## Update HUD
	hud.populate_stash_list(stash, selected_actor)
	update_hud_actions_disabled_check()

func discard_hand():
	if VERBOSE_CARDS: p("Discarding hand...")
	unhold_action()
	
	var to_erase: Array[Action] = actions_in_hand.duplicate()
	for card in to_erase: ## because you can't iterate over an array and erase elements, we copy the array first...
		discard(card)

	hud.populate_actions_list([], selected_actor) ## Update HUD
	update_hud_actions_disabled_check()


func draw_next_card():
	if draw_deck.is_empty():
		if not discard_deck.is_empty():
			discard_deck.shuffle()
			draw_deck.append_array(discard_deck)
			if VERBOSE_CARDS: p("Reshuffled %d cards in discard deck into draw deck." % discard_deck.size())
			discard_deck.clear()
		else:
			if VERBOSE_CARDS: p("Out of cards!!"); push_error("Out of cards!!")
			return

	var drawn: Action = draw_deck.pop_front()
	actions_in_hand.push_back(drawn)
	if VERBOSE_CARDS: p("Drew action: %s" % drawn)

## Add this card to discard_deck and erase from actions_in_hand.
## Will assert that the card is actually in your hand...
func discard(card):
	assert(card in actions_in_hand, "Trying to discard %s from a foreign source." % card)
	if (not card in always_available_deck) && (not card is ActionChangeStance):
		discard_deck.append(card)
		if VERBOSE_CARDS: p("Sent %s to discard deck." % card)
	actions_in_hand.erase(card)
	if VERBOSE_CARDS: p("Cleared %s from hand." % card)

var _currently_playing_action: bool = false
func play_held_action_at(coords: Vector2i):
	if not current_held_action.can_player_enter(selected_actor):
		return
	
	if current_held_action.is_obstructable:
		## Check obstructions
		if coords != selected_actor.find_last_unobstructed_tile(selected_actor.current_tile_coords, coords):
			hud.popup_label("Obstructed!", selected_actor)
			return
			
	TargetFinder.clear_all_highlights()
	deselect_tile()
	
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
	
	if current_held_action.remove_from_hand_after_use:
		if current_held_action in stash:
			remove_from_stash(current_held_action)
			## don't add to the Discard deck
		
		else:
			if current_held_action.action_category == Action.ActionCategory.CONSUMABLE:
				remove_from_deck(current_held_action)
			else:
				discard(current_held_action)
	
	if current_held_action.allow_facing_after:
		position_for_facing = selected_actor.global_position
		await get_facing(position_for_facing)
	
	_currently_playing_action = false
	unhold_action()
	hud.populate_actions_list(actions_in_hand, selected_actor)
	update_hud_actions_disabled_check()
	hud.end_turn_button.disabled = false
	hud.end_turn_button.show()

## Appends [param card] to the [member draw_deck].
func add_to_deck(card: Action) -> void:
	if card == null:
		if VERBOSE_CARDS: p("Tried to add a null card to the draw deck.")
		return
	if VERBOSE_CARDS: p("Appending %s to back of draw deck." % card)
	draw_deck.push_back(card)

## Finds and erases the first instance of [param card] in each array [member discard_deck], [member draw_deck], and [member actions_in_hand].
func remove_from_deck(card: Action) -> void:
	if card == null:
		if VERBOSE_CARDS: p("Card to remove was null")
		return
	if card in discard_deck:
		discard_deck.erase(card)
		if VERBOSE_CARDS: p("Erased card %s from [b]discard[/b] deck." % card)
	if card in draw_deck:
		draw_deck.erase(card)
		if VERBOSE_CARDS: p("Erased card %s from [b]draw[/b] deck." % card)
	if card in actions_in_hand:
		actions_in_hand.erase(card)
		if VERBOSE_CARDS: p("Erased card %s from [b]hand[/b]." % card)

func add_to_stash(card: Action) -> void:
	if card == null:
		if VERBOSE or VERBOSE_CARDS: p("Card to stash was null")
		return
	card.action_category = Action.ActionCategory.CONSUMABLE
	stash.append(card)
	hud.populate_stash_list(stash, selected_actor)
	update_hud_actions_disabled_check()
	if VERBOSE or VERBOSE_CARDS: p("Stashed card: %s" % card)

func remove_from_stash(card: Action) -> void:
	stash.erase(card)
	hud.populate_stash_list(stash, selected_actor)
	update_hud_actions_disabled_check()
	if VERBOSE or VERBOSE_CARDS: p("Erased %s from Stash." % card)
	
func get_all_cards(and_stash: bool = false) -> Array[Action]:
	var all_together: Array[Action]
	if and_stash:
		all_together = actions_in_hand + draw_deck + discard_deck + stash
	else:
		all_together = actions_in_hand + draw_deck + discard_deck
	if VERBOSE_CARDS: p("(%d cards this moment)" % all_together.size())
	return all_together
	
var last_stance_status_key
## Arg is a UID
func change_stance(new_stance_uid) -> void:
	## Remove all cards from the old stance, add current stance cards.
	## And also somehow don't mess up the card stack (shuffle).
	var starting_cards_in_hand: int = actions_in_hand.size()
	var _new_cards: Array[Action] ## To shuffle later
	
	var new_stance_path = ResourceUID.uid_to_path(new_stance_uid)
	assert(new_stance_path)
	
	var new_stance: Stance = ResourceLoader.load(new_stance_path)
	assert(new_stance != current_stance, "Tried to change stance to same stance")
	
	for actor in actors:
		actor.erase_keyed_statuses(last_stance_status_key)
	last_stance_status_key = new_stance_uid
	
	if current_stance != null:
		if VERBOSE_CARDS: p("Removing old stance cards...")
		for card in get_all_cards():
			if card in current_stance.actions:
				remove_from_deck(card)
	
	current_stance = new_stance
	
	if VERBOSE_CARDS: p("Adding new stance cards to draw deck...")
	for card in new_stance.actions:
		_new_cards.append(card)
		add_to_deck(card)
	draw_deck.shuffle() ## NOTE we also are shuffling the deck when this is called.
	if VERBOSE_CARDS: p("Shuffled draw deck: %d cards." % draw_deck.size())
		
	
	if REPLACE_STANCE_CARDS_IN_HAND:
		if VERBOSE or VERBOSE_CARDS: p("Replacing %d lost held old stance actions..." % (starting_cards_in_hand - actions_in_hand.size()))
		_new_cards.shuffle()
		
		while actions_in_hand.size() < starting_cards_in_hand:
			if _new_cards.is_empty():
				if VERBOSE: p("Ran out of new stance actions to draw.")
				break
			
			var drawn: Action = _new_cards.pop_back()
			draw_deck.erase(drawn)
			actions_in_hand.push_back(drawn)
			if VERBOSE: p("Drew action: %s" % drawn.ui_title)
#endregion

func select_actor(actor: Actor) -> void:
	for a in actors: a.show_acting_indicator(false) ## UI
	if actor == null:
		selected_actor = null
		if VERBOSE: p("Deselected actor")
	else:
		assert(actor in actors)
		selected_actor = actor
		selected_actor.show_acting_indicator(true) ## UI
		if VERBOSE: p("Selected actor %s" % selected_actor)

func deselect_actor() -> void: select_actor(null)

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

func update_hud_actions_disabled_check() -> void:
	hud.actions_panel.check_actions_disabled(selected_actor)
	hud.stash_panel.check_actions_disabled(selected_actor)

func clear_all_npc_action_previews() -> void:
	for actor in Level.get_all_actors_in_play_order():
		if actor is AIActor:
			actor.hide_preview_for_actions()

## This method updates AIActor action previews.
## This method calls every [method AIActor.hide_preview_attack], then finds the
## actor on our mouse-hovered tile and calls [method AIActor.preview_ai_attack].
func update_npc_action_preview() -> void:
	clear_all_npc_action_previews()

	#check if there is an AI actor on selected tile needs their preview added
	if is_active:
		if(_last_hovered_tile != null and current_held_action == null): #prevents preview from being added when an action is being held
			var actor = Level.get_actor_at(_last_hovered_tile) as AIActor
			if actor != null:
				actor.preview_ai_attack()

## Call to stun the player. Different behavior from [AIActor], where their action queue is cleared...
## Typically called at the start of your turn by the status effect Stunned.
var addtl_energy_cost: int = 0
func stunned(_status: StatusStunned) -> void:
	## Decrease energy this turn by 1 point.
	addtl_energy_cost += 1
	if VERBOSE:
		p("Stunned--additional energy cost this turn is %d." % addtl_energy_cost)

func clear_addtl_energy_cost() -> void:
	addtl_energy_cost = 0
