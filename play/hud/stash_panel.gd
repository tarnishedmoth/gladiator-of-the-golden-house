class_name StashPanel extends ActionButtonPanel
## Displays persistent bonus cards (stash) that carry between levels.

func _ready() -> void:
	actions_container = $VBoxContainer/StashActions

func populate_stash(stash: Array[Action], selected_actor: Actor) -> void:
	populate_action_buttons(stash, selected_actor)
	visible = not stash.is_empty()
