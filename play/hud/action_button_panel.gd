class_name ActionButtonPanel extends PanelContainer
## Base class for panels that display a list of Action buttons (hand, stash, etc).

signal action_button_pressed(action: Action)
signal action_hover_started(action: Action)
signal action_hover_ended()

var action_buttons: Dictionary[ButtonWithBlips, Action]
var actions_container: VBoxContainer ## Set by subclass in _ready or @onready.

func get_action_assigned_to(button: ButtonWithBlips) -> Action:
	if button in action_buttons:
		return action_buttons[button]
	else:
		return null

func clear_all_actions() -> void:
	for card in action_buttons.keys():
		card.queue_free()
	action_buttons.clear()

func populate_action_buttons(actions: Array[Action], selected_actor: Actor) -> void:
	clear_all_actions()
	for card in actions:
		var new_button: ButtonWithBlips = ButtonWithBlips.new()
		actions_container.add_child(new_button)
		action_buttons[new_button] = card
		new_button.set_blips(card.energy_cost)
		new_button.text = card.ui_title
		new_button.custom_minimum_size = Vector2(0.0, 26.0)
		
		var icon = card.ui_icon
		if icon is Texture2D:
			new_button.icon = icon
			
		new_button.pressed.connect(_on_action_button_pressed.bind(new_button))
		new_button.mouse_entered.connect(_on_action_hover_started.bind(new_button))
		new_button.mouse_exited.connect(_on_action_hover_ended.bind(new_button))
		new_button.focus_entered.connect(_on_action_hover_started.bind(new_button))
		new_button.focus_exited.connect(_on_action_hover_ended.bind(new_button))
	check_actions_disabled(selected_actor)

func check_actions_disabled(selected_actor: Actor) -> void:
	for button in action_buttons:
		button.disabled = not action_buttons[button].can_player_enter(selected_actor, true) if selected_actor else true

func _on_action_button_pressed(button) -> void:
	var action: Action = get_action_assigned_to(button)
	if action != null:
		action_button_pressed.emit(action)
	else:
		push_error("Pressed action button gets null action.")

func _on_action_hover_started(button) -> void:
	var action: Action = get_action_assigned_to(button)
	action_hover_started.emit(action)

func _on_action_hover_ended(_button) -> void:
	action_hover_ended.emit()
