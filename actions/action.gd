@abstract class_name Action extends ResourceState

enum ActionCategory{
	COMBAT,
	MOVEMENT,
	SKILL,
	CONSUMABLE,
	SPECIAL,
}

const ACTION_CATEGORY_NAMES = {
	ActionCategory.MOVEMENT:"Movement",
	ActionCategory.COMBAT: "Combat",
	ActionCategory.SKILL: "Skill",
	ActionCategory.CONSUMABLE: "Consumable",
	ActionCategory.SPECIAL: "Special",
}

@export var ui_title: String ## Displayed in the Actions list
@export var ui_description: String ## Displayed when hovering over an action
@export var action_category: ActionCategory
var ui_category: String: 
	get:
		return ACTION_CATEGORY_NAMES.get(action_category,"Unknown")

var _actor: Actor ## The target this action will run on.
func set_actor(actor: Actor) -> void:
	self._actor = actor

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
	
## Use to execute actions with an actor.
## It will set the target actor before running [method enter].
func enter_with(actor: Actor, from: Action) -> void:
	set_actor(actor)
	enter(from)

func run_on(actor: Actor) -> void:
	## Ask the actor's state machine to run this Action
	actor.run_action(self)
