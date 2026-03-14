class_name LevelHUD extends CanvasLayer

const SELECTED_ACTOR_ACTION_PANEL = preload("uid://dxvurd53homf")
const POPUP_NUMBER_INDICATOR = preload("uid://rim8rln2dqsb")

#static var instance: LevelHUD:
	#set(v):
		#if (v != null) and (instance != null):
			#assert(not is_instance_valid(instance), "More than one instance in memory")
		#instance = v
		
var selected_actor_action_panels: Array[HUDSelectedActorActionPanel]

@onready var hover_panel: HUDHoverPanel = %HoverPanel
@onready var actions_panel: ActionsPanel = %ActionsPanel
@onready var actions_hover_panel: HUDActionHoverPanel = %ActionsHoverPanel
@onready var selected_actor_action_panels_v_box_container: VBoxContainer = %SelectedActorActionPanelsVBoxContainer
@onready var end_turn_button: Button = %EndTurnButton

#func _enter_tree() -> void:
	#instance = self
	#
#func _exit_tree() -> void:
	#if instance == self: instance = null

func _ready() -> void:
	## Setup
	hover_panel.modulate = Color.TRANSPARENT
	
	actions_hover_panel.modulate = Color.TRANSPARENT
	#actions_hover_panel.hide()
	
	actions_panel.action_button_pressed.connect(_on_action_pressed)
	actions_panel.action_hover_started.connect(_on_action_hover_start)
	actions_panel.action_hover_ended.connect(_on_action_hover_ended)
	
	Level.get_instance().current_director_changed.connect(_on_current_director_changed)

func show_hover_panel(show_:bool = true) -> void:
	if not show_:
		Juice.fade_out(hover_panel)
		clear_all_selected_actor_action_panels()
	else:
		Juice.advanced_fade(hover_panel, Juice.SMOOTH, Color.WHITE)

func populate_hover_panel(tile_coords: Vector2i, actor: Actor) -> void:
	## Replace tile_coords with TileData or whatever more complex object if we need to.
	clear_all_selected_actor_action_panels()
	if actor:
		hover_panel.populate_using_actor_data(actor)
		if actor.get_action_queue():
			if not actor.get_action_queue().queue.is_empty():
				## Show action details
				for action in actor.get_action_queue().queue:
					make_selected_actor_action_panel(actor, action)
	else:
		hover_panel.clear_all()
		hover_panel.title.text = "[center]" + str(tile_coords)

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


## Action Panel signals
func _on_action_pressed(action: Action) -> void:
	var player = Level.get_current_director()
	assert(player is Player)
	if player is Player:
		player.hold_action(action)

func populate_actions_list(hand: Array[Action], selected_actor: Actor) -> void:
	actions_panel.populate_actions(hand, selected_actor)

func show_actions_hover_panel(show_:bool = true) -> void:
	if not show_:
		actions_hover_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		Juice.fade_out(actions_hover_panel)
	else:
		actions_hover_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		Juice.advanced_fade(actions_hover_panel, Juice.SMOOTH, Color.WHITE)
		
func _on_action_hover_start(action:Action) -> void:
	actions_hover_panel.clear_all()
	actions_hover_panel.populate_using_action_data(action)

func _on_action_hover_ended() -> void:
	actions_hover_panel.clear_all()


func _on_current_director_changed(new_director: Director) -> void:
	end_turn_button.disabled = not new_director is Player

const END_TURN_TEXT: String = "End Turn"
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


func _on_end_turn_button_up() -> void:
	var player = Level.get_current_director()
	if player is Player:
		kill_end_turn_hold_tween()
		player.user_released_end_turn_button()

func set_end_turn_text(to_append = null) -> void:
	if not to_append:
		end_turn_button.text = END_TURN_TEXT
	else:
		var _to_append
		if to_append is float:
			_to_append = "%.1f" % to_append
		else:
			_to_append = to_append
		end_turn_button.text = END_TURN_TEXT + " (" + (str(_to_append) if _to_append is not String else _to_append) + ")" ##lol

var popups: Array[Label]
func popup_label(text: Variant, re_parent: Node2D, recolor: Color = Color.WHITE) -> void:
	var popup: Label = POPUP_NUMBER_INDICATOR.instantiate()
	popup.text = str(text) if not (text is String) else text
	popup.modulate = recolor
	
	re_parent.add_child(popup)
	
	var _offset: Vector2 = Vector2.ZERO
	for other in popups:
		if is_instance_valid(other): ## Not sure how this bug is happening but
			if other.global_position.distance_to(re_parent.global_position) < popup.size.y * 2.2:
				_offset.y += popup.size.y
			
	popups.append(popup)
	popup.position -= popup.size / 2.0
	popup.position += _offset
	
	var t = Juice.flash(popup, Juice.PulsePresets.ThreeFast, recolor, Color.WHITE)
	t.tween_callback(popups.erase.bind(popup))
	t.tween_callback(popup.free)
