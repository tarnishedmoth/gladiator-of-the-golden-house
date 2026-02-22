@abstract class_name Action extends ResourceState

const NO_PATTERN = [] ## Empty value used for targeting logic.

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
		return ACTION_CATEGORY_NAMES.get(action_category,"")
		
@export var energy_cost: int = 0

var _actor: Actor ## The actor that will run this action. This is not any "target" such as for dealing damage.
func set_actor(actor: Actor) -> void:
	self._actor = actor
	
var _target: ## Vector2i absolute
	get:
		if not _target:
			return _actor.current_tile_coords
		else:
			return _target
			
func set_target(target) -> void:
	if target is Actor:
		_target = target.current_tile_coords
	elif target is Vector2i:
		_target = target

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
func enter_with(actor: Actor, from: Action = null) -> void:
	set_actor(actor)
	enter(from)
	
## Ask the actor's state machine to run this Action
func run_on(actor: Actor) -> void:
	actor.run_action(self)
