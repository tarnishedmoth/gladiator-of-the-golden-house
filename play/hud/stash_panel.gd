class_name StashPanel extends PanelContainer

signal action_button_pressed(action: Action)
signal action_hover_started(action: Action)
signal action_hover_ended()

var stash_actions: Dictionary[ButtonWithBlips, Action]

@onready var actions_container: VBoxContainer = $VBoxContainer/StashActions

func get_action_assigned_to(button: ButtonWithBlips) -> Action:
	if button in stash_actions:
		return stash_actions[button]
	else:
		return null

func clear_all_actions() -> void:
	for card in stash_actions.keys():
		card.queue_free()
	stash_actions.clear()

func populate_stash(stash: Array[Action], selected_actor: Actor) -> void:
	clear_all_actions()

	for card in stash:
		var new_button: ButtonWithBlips = ButtonWithBlips.new()
		actions_container.add_child(new_button)

		stash_actions[new_button] = card

		new_button.set_blips(card.energy_cost)
		new_button.text = card.ui_title

		var icon = card.ui_icon
		if icon is Texture2D:
			new_button.icon = icon

		new_button.pressed.connect(_on_action_button_pressed.bind(new_button))
		new_button.mouse_entered.connect(_on_action_hover_started.bind(new_button))
		new_button.mouse_exited.connect(_on_action_hover_ended.bind(new_button))
		new_button.focus_entered.connect(_on_action_hover_started.bind(new_button))
		new_button.focus_exited.connect(_on_action_hover_ended.bind(new_button))

	check_actions_disabled(selected_actor)
	visible = not stash.is_empty()

func check_actions_disabled(selected_actor: Actor) -> void:
	for button in stash_actions:
		button.disabled = not stash_actions[button].can_player_enter(selected_actor, true) if selected_actor else true

func _on_action_button_pressed(button) -> void:
	var action: Action = get_action_assigned_to(button)
	if action != null:
		action_button_pressed.emit(action)
	else:
		push_error("Pressed stash button gets null action.")

func _on_action_hover_started(button) -> void:
	var hud: LevelHUD = Level.get_hud()
	var action: Action = get_action_assigned_to(button)

	action_hover_started.emit(action)
	hud.show_actions_hover_panel()

func _on_action_hover_ended(_button) -> void:
	var hud: LevelHUD = Level.get_hud()

	hud.show_actions_hover_panel(false)
	action_hover_ended.emit()
