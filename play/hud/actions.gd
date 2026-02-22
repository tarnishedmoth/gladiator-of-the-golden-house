class_name ActionsPanel extends PanelContainer

signal action_button_pressed(action: Action)

var actions_in_hand: Dictionary[ButtonWithBlips, Action] ## UI element in scene, Action resource from PlayerDirector

@export var actions: VBoxContainer


func get_action_assigned_to(button: ButtonWithBlips) -> Action:
	if button in actions_in_hand:
		return actions_in_hand[button]
	else:
		return null


func clear_all_actions() -> void:
	assert(actions)
	for card in actions_in_hand.keys():
		card.queue_free()
	actions_in_hand.clear()

func populate_actions(hand: Array[Action]) -> void:
	assert(actions)
	clear_all_actions()
	
	for card in hand:
		var new_button: ButtonWithBlips = ButtonWithBlips.new()
		actions.add_child(new_button)
		
		actions_in_hand[new_button] = card
		
		new_button.set_blips(card.energy_cost)
		new_button.text = card.ui_title
		
		## picking an action
		new_button.pressed.connect(_on_action_button_pressed.bind(new_button))
		## e.g. popup details or other reactions
		new_button.mouse_entered.connect(_on_action_hover_started.bind(new_button))
		new_button.mouse_exited.connect(_on_action_hover_ended.bind(new_button))
		## Controller/keyboard/accessibility support
		new_button.focus_entered.connect(_on_action_hover_started.bind(new_button))
		new_button.focus_exited.connect(_on_action_hover_ended.bind(new_button))

func _on_action_button_pressed(button) -> void:
	var action: Action = get_action_assigned_to(button)
	if action != null:
		action_button_pressed.emit(action) ## the HUD handles telling the PlayerDirector we picked an action
	else:
		push_error("pressed action button gets null action.")

func _on_action_hover_started(button) -> void:
	pass
	
func _on_action_hover_ended(button) -> void:
	pass
