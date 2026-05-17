class_name ActionsPanel extends ActionButtonPanel

@onready var actions_header: ButtonWithBlips = %ActionsHeader

@export var actions: VBoxContainer

func _ready() -> void:
	actions_container = actions

func check_actions_disabled(selected_actor: Actor) -> void:
	actions_header.set_blips(selected_actor.energy)
	super.check_actions_disabled(selected_actor)
