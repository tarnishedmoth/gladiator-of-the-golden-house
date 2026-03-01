class_name LevelHUD extends CanvasLayer

#static var instance: LevelHUD:
	#set(v):
		#if (v != null) and (instance != null):
			#assert(not is_instance_valid(instance), "More than one instance in memory")
		#instance = v

@onready var hover_panel: HUDHoverPanel = %HoverPanel
@onready var actions_panel: ActionsPanel = %ActionsPanel
@onready var actions_hover_panel: HUDActionHoverPanel = %ActionsHoverPanel
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
	actions_panel.action_button_pressed.connect(_on_action_pressed)
	actions_panel.action_hover_started.connect(_on_action_hover_start)
	actions_panel.action_hover_ended.connect(_on_action_hover_ended)
	
	Level.get_instance().current_director_changed.connect(_on_current_director_changed)

func show_hover_panel(show_:bool = true) -> void:
	if not show_:
		Juice.fade_out(hover_panel)
	else:
		Juice.advanced_fade(hover_panel, Juice.SMOOTH, Color.WHITE)

func populate_hover_panel(tile_coords: Vector2i, actor: Actor) -> void:
	## Replace tile_coords with TileData or whatever more complex object if we need to.
	if actor:
		hover_panel.populate_using_actor_data(actor)
	else:
		hover_panel.clear_all()
		hover_panel.title.text = "[center]" + str(tile_coords)

## Action Panel signals
func _on_action_pressed(action: Action) -> void:
	var player = Level.get_current_director()
	assert(player is Player)
	if player is Player:
		player.hold_action(action)

func populate_actions_list(hand: Array[Action]) -> void:
	actions_panel.populate_actions(hand)

func show_actions_hover_panel(show_:bool = true) -> void:
	if not show_:
		Juice.fade_out(actions_hover_panel)
	else:
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
