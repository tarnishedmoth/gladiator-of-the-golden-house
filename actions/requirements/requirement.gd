@abstract class_name ActionRequirement

@export var ui_display_title: String
@export var ui_display_description: String

## Override me! Return true if the requirements are met.
@abstract func check(player_data) -> bool
