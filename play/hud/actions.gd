class_name ActionsPanel extends ActionButtonPanel

@onready var actions_header: ButtonWithBlips = %ActionsHeader

@export var actions: VBoxContainer

func _ready() -> void:
	actions_container = actions

func populate_actions(hand: Array[Action], selected_actor: Actor) -> void:
	populate_action_buttons(hand, selected_actor)

func check_actions_disabled(selected_actor: Actor) -> void:
	actions_header.set_blips(selected_actor.energy)
	super.check_actions_disabled(selected_actor)

func get_button_assigned_to(action: Action) -> ButtonWithBlips:
	if action in action_buttons.values():
		return action_buttons.find_key(action)
	else:
		return null
