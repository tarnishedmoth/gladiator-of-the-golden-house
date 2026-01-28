@abstract class_name Action extends State

@export var ui_title: String ## Displayed in the Actions list
@export var ui_description: String ## Displayed when hovering over an action

## A callable must accept `player_data` argument and return a boolean.
## Consider populating the requirements array in _init, or _enter_tree.
var requirements: Array[ActionRequirement]

func can_player_enter(player_data) -> bool:
	## TODO define what player data looks like. I think it's just gonna be the Player object (Director).
	for requirement: ActionRequirement in requirements:
		if requirement.check(player_data) == false:
			if debug: p("Failed requirement check: %s" % requirement)
			return false
			
		elif debug: p("Passed requirement check: %s" % requirement)
		
	return true
