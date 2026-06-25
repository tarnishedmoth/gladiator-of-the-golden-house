class_name LevelHUD extends CanvasLayer

const END_TURN_TEXT: String = "End Turn"
const SELECTED_ACTOR_ACTION_PANEL = preload("uid://dxvurd53homf")
const POPUP_NUMBER_INDICATOR = preload("uid://rim8rln2dqsb")

const STYLE_DAMAGE: PopupStyle = preload("uid://bqhq0381fj7a3")
const STYLE_STATUS: PopupStyle = preload("uid://bqhq0381urka3")
const STYLE_STATUS_DEBUFF: PopupStyle = preload("uid://m56nl7uvb2lv")
const STYLE_NEGATED: PopupStyle = preload("uid://bqhq0381djca3")
const STYLE_VULNERABILITY: PopupStyle = preload("uid://sjdlsxm6sqin")

var selected_actor_action_panels: Array[HUDSelectedActorActionPanel]

@onready var root: Control = %Root
@onready var hover_panel: HUDHoverPanel = %HoverPanel
@onready var actions_panel: ActionsPanel = %ActionsPanel
@onready var stash_panel: StashPanel = %StashPanel
@onready var actions_hover_panel: HUDActionHoverPanel = %ActionsHoverPanel
@onready var selected_actor_action_panels_v_box_container: VBoxContainer = %SelectedActorActionPanelsVBoxContainer
@onready var end_turn_button: Button = %EndTurnButton
@onready var end_turn_progress_bar: ColorRect = %EndTurnProgressBar

func _ready() -> void:
	## Initially hide the hud
	root.hide()
	root.modulate = Color.TRANSPARENT
	
	## Setup
	hover_panel.modulate = Color.TRANSPARENT

	actions_hover_panel.modulate = Color.TRANSPARENT
	show_actions_hover_panel(false)

	actions_panel.action_button_pressed.connect(_on_action_pressed)
	actions_panel.action_hover_started.connect(_on_action_hover_start)
	actions_panel.action_hover_ended.connect(_on_action_hover_ended)

	stash_panel.action_button_pressed.connect(_on_stash_action_pressed)
	stash_panel.action_hover_started.connect(_on_action_hover_start)
	stash_panel.action_hover_ended.connect(_on_action_hover_ended)

	Level.get_instance().current_director_changed.connect(_on_current_director_changed)


var visibility_tween: Tween
func show_hud(showing: bool) -> void:
	if visibility_tween:
		visibility_tween.kill()
	
	if showing:
		visibility_tween = create_tween()
		visibility_tween.tween_property(root, ^"modulate", Color.WHITE, Juice.FAST)
		if not root.visible:
			root.show()
	else:
		if root.visible:
			visibility_tween = create_tween()
			visibility_tween.tween_property(root, ^"modulate", Color.TRANSPARENT, Juice.FAST)
			visibility_tween.tween_callback(root.hide)


func show_hover_panel(show_:bool = true) -> void:
	if not show_:
		Juice.fade_out(hover_panel)
		clear_all_selected_actor_action_panels()
	else:
		Juice.advanced_fade(hover_panel, Juice.SMOOTH, Color.WHITE)


enum _Panel {
	ACTOR = 0,
	PICKUP = 1,
}
var _last_shown: _Panel
var _previous_tile_coords: Vector2i
func populate_hover_panel(tile_coords: Vector2i) -> void:
	## Replace tile_coords with TileData or whatever more complex object if we need to.
	clear_all_selected_actor_action_panels()
	
	var actor: Actor = Level.get_actor_at(tile_coords)
	var pickup: PickUp = Level.get_pick_up_at(tile_coords)
	
	
	if tile_coords == _previous_tile_coords and actor and pickup:
		## Pagination for overlapping entities
		match _last_shown:
			_Panel.PICKUP:
				_populate_actor_hover_panel(actor)
			_Panel.ACTOR:
				_populate_pickup_hover_panel(pickup)
	
	else:
		## Fresh coordinate
		if actor:
			_populate_actor_hover_panel(actor)
		elif pickup:
			_populate_pickup_hover_panel(pickup)
		else:
			hover_panel.clear_all()
			hover_panel.title.text = "[center]" + str(tile_coords)
	
	_previous_tile_coords = tile_coords
	
func _populate_actor_hover_panel(actor: Actor) -> void:
	_last_shown = _Panel.ACTOR ## Pagination for overlapping entities
	
	hover_panel.populate_using_actor_data(actor)
	if actor.get_action_queue():
		if not actor.get_action_queue().queue.is_empty():
			## Show action details
			for action in actor.get_action_queue().queue:
				make_selected_actor_action_panel(actor, action)
				
func _populate_pickup_hover_panel(pickup: PickUp) -> void:
	_last_shown = _Panel.PICKUP ## Pagination for overlapping entities
	
	hover_panel.populate_using_pickup_data(pickup)


func make_selected_actor_action_panel(actor: Actor, action: Action) -> void:
	var panel: HUDSelectedActorActionPanel = SELECTED_ACTOR_ACTION_PANEL.instantiate()
	panel.populate(actor, action)
	selected_actor_action_panels_v_box_container.add_child(panel)
	selected_actor_action_panels.push_back(panel)
	Juice.fade_in(panel)

func clear_all_selected_actor_action_panels() -> void:
	for child in selected_actor_action_panels:
		child.queue_free()
	selected_actor_action_panels.clear()

func on_player_running_action(action: Action) -> void:
	actions_panel.on_player_running_action(action)

## Action Panel signals
func _on_action_pressed(action: Action) -> void:
	var player = Level.get_current_director()
	assert(player is Player)
	if player is Player:
		player.hold_action(action)

func _on_stash_action_pressed(action: Action) -> void:
	var player = Level.get_current_director()
	assert(player is Player)
	if player is Player:
		player.hold_action(action)

func populate_actions_list(hand: Array[Action], selected_actor: Actor) -> void:
	actions_panel.populate_action_buttons(hand, selected_actor)

func populate_stash_list(stash: Array[Action], selected_actor: Actor) -> void:
	stash_panel.populate_stash(stash, selected_actor)

var actions_hover_panel_tween: Tween
func show_actions_hover_panel(show_:bool = true) -> void:
	if not show_:
		actions_hover_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		if actions_hover_panel_tween:
			actions_hover_panel_tween.kill()
		actions_hover_panel_tween = actions_hover_panel.create_tween()
		actions_hover_panel_tween.tween_property(actions_hover_panel, ^"modulate", Color.TRANSPARENT, Juice.SNAP)
		actions_hover_panel_tween.tween_callback(actions_hover_panel.hide)
	else:
		actions_hover_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		
		if actions_hover_panel_tween:
			actions_hover_panel_tween.kill()
		actions_hover_panel_tween = actions_hover_panel.create_tween()
		actions_hover_panel_tween.tween_property(actions_hover_panel, ^"modulate", Color.WHITE, Juice.SMOOTH)
		actions_hover_panel.show()

func _on_action_hover_start(action:Action) -> void:
	actions_hover_panel.clear_all()
	actions_hover_panel.populate_using_action_data(action)
	show_actions_hover_panel()

func _on_action_hover_ended() -> void:
	actions_hover_panel.clear_all()
	show_actions_hover_panel(false)

func _on_current_director_changed(new_director: Director) -> void:
	actions_panel.actions_header.set_blips(0)
	var is_player: bool = new_director is Player
	end_turn_button.disabled = not is_player
	# end_turn_progress_bar.size.x = 0
	show_hud(is_player)


var end_turn_hold_tween: Tween
func kill_end_turn_hold_tween():
	if end_turn_hold_tween:
		end_turn_hold_tween.kill()
	set_end_turn_text()

func _on_end_turn_button_down() -> void:
	var player = Level.get_current_director()
	if player is Player:
		var turn_is_ending_immediately: bool = player.user_pressed_end_turn_button()

		kill_end_turn_hold_tween()

		if not turn_is_ending_immediately:
			var hold_duration_remaining = player.HOLD_TIME_TO_END_TURN_EARLY
			end_turn_hold_tween = create_tween()
			end_turn_hold_tween.tween_method(set_end_turn_text, hold_duration_remaining, 0, hold_duration_remaining)
			end_turn_progress_bar.size.x = 0



func _on_end_turn_button_up() -> void:
	var player = Level.get_current_director()
	if player is Player:
		kill_end_turn_hold_tween()
		player.user_released_end_turn_button()

func set_end_turn_text(to_append = null) -> void:
	if not to_append:
		end_turn_button.text = END_TURN_TEXT
		end_turn_progress_bar.size.x = 0
	else:
		var _to_append
		if to_append is float:
			_to_append = "%.1f" % to_append
		else:
			_to_append = to_append
		end_turn_button.text = END_TURN_TEXT + " (" + (str(_to_append) if _to_append is not String else _to_append) + ")" ##lol
		
		# maybe this should be done in a second tween instead:
		var player = Level.get_current_director()
		if player is Player:
			end_turn_progress_bar.size.x = end_turn_button.size.x * (end_turn_hold_tween.get_total_elapsed_time()/player.HOLD_TIME_TO_END_TURN_EARLY)
			print("tween elapsed time: "+str(end_turn_hold_tween.get_total_elapsed_time()))
			print("tween progress bar size: "+str(end_turn_progress_bar.size.x))

var popups: Array[Label]

func popup_label(text: String, actor: Actor, style: PopupStyle = STYLE_STATUS) -> Label:
	return _popup_transient(text, actor, style)

func popup_damage(value: int, actor: Actor) -> Label:
	return _popup_transient(value, actor, STYLE_DAMAGE)
	
func popup_healing(value: int, actor: Actor) -> Label:
	return _popup_transient("+%s" % value, actor, STYLE_STATUS)
	
func popup_knockback(text: String, actor: Actor) -> Label:
	return _popup_transient(text, actor, STYLE_STATUS)

func popup_status(text: String, actor: Actor, is_debuff: bool = false) -> Label:
	if is_debuff:
		return _popup_transient(text, actor, STYLE_STATUS_DEBUFF)
	else:
		return _popup_transient(text, actor, STYLE_STATUS)

func popup_negated(value: int, actor: Actor) -> Label:
	return _popup_transient(value, actor, STYLE_NEGATED)
	
func popup_vulnerability(value: float, actor: Actor) -> Label:
	return _popup_transient("%.1fx" % value, actor, STYLE_VULNERABILITY)

## Caller owns lifetime; release via [method clear_popup_persistent_label].
func popup_label_persistent(text: Variant, actor: Actor, style: PopupStyle) -> Label:
	var screen_pos := _screen_pos_for(actor, 0.0)
	return _spawn_popup(text, screen_pos, style, Vector2(10.0, 30))

func clear_popup_persistent_label(popup: Label) -> void:
	popups.erase(popup)
	popup.queue_free()

func _popup_transient(text: Variant, actor: Actor, style: PopupStyle) -> Label:
	var jitter_x := randf_range(-style.horizontal_jitter, style.horizontal_jitter)
	var screen_pos := _screen_pos_for(actor, jitter_x)
	var popup := _spawn_popup(text, screen_pos, style, Vector2.ZERO)
	popup.scale = Vector2(style.pop_scale, style.pop_scale)

	var tween := popup.create_tween().set_parallel(true)
	tween.tween_property(popup, ^"scale", Vector2.ONE, style.pop_duration)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(popup, ^"position:y", popup.position.y - style.rise_distance, style.rise_duration)\
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(popup, ^"modulate:a", 0.0, style.fade_duration)\
		.set_delay(style.rise_duration - style.fade_duration)
	tween.chain().tween_callback(popups.erase.bind(popup))
	tween.tween_callback(popup.free)
	return popup

func _spawn_popup(text: Variant, screen_pos: Vector2, style: PopupStyle, base_offset: Vector2) -> Label:
	var popup: Label = POPUP_NUMBER_INDICATOR.instantiate()
	popup.label_settings = style.label_settings
	popup.modulate = style.color
	popup.text = str(text)
	Level.get_instance().add_child(popup)

	var stack_offset := _compute_stack_offset(screen_pos, popup.size)
	popups.append(popup)
	## Center pivot so the pop_scale tween scales from the middle of the label.
	popup.pivot_offset = popup.size / 2.0
	popup.global_position = screen_pos - popup.size / 2.0 + base_offset + stack_offset
	return popup

## Cumulative offset per overlap (not per cluster): N nearby popups stack N rows.
## Proximity threshold is ~2x line height + a margin, tuned visually.
func _compute_stack_offset(screen_pos: Vector2, popup_size: Vector2) -> Vector2:
	var stack_offset := Vector2.ZERO
	for other in popups:
		if other.global_position.distance_to(screen_pos) < popup_size.y * 2.2:
			stack_offset.y += popup_size.y
	return stack_offset

func _screen_pos_for(actor: Actor, jitter_x: float) -> Vector2:
	return _actor_to_screen(actor) + actor.label_anchor + Vector2(jitter_x, 0)

func _actor_to_screen(actor: Actor) -> Vector2:
	return actor.get_canvas_transform() * actor.global_position
