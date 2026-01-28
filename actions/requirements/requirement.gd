class_name ActionRequirement

@export var ui_display_title: String
@export var ui_display_description: String

## Override me!
func check(player_data) -> bool:
	return true
