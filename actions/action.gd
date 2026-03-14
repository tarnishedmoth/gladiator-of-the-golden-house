@abstract class_name Action extends ResourceState

## Vars and methods are kinda spread out/mixed together in this script, sorry about that

const NO_PATTERN: Array[Vector2i] = [Vector2i(0,0)] ## Empty value used for targeting logic.

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

const ACTION_CATEGORY_ICONS: Dictionary[ActionCategory, Texture2D] = {
	ActionCategory.MOVEMENT: preload("uid://disinbamqthvh"),
	ActionCategory.COMBAT: preload("uid://c7ers5ee7squq"),
	ActionCategory.SKILL: null, ## TODO
	ActionCategory.CONSUMABLE: null, ## TODO
	ActionCategory.SPECIAL: null, ## TODO
}

#@export_group("UI")
@export var ui_title: String ## Displayed in the Actions list
@export_multiline() var ui_description: String ## Displayed when hovering over an action
@export var ui_icon: Texture2D: ## If left undefined, will use one according to its [member action_category].
	get:
		if ui_icon: return ui_icon
		else: return ACTION_CATEGORY_ICONS.get(action_category)
@export var action_category: ActionCategory ## See also [member ui_category].
var ui_category: String: ## Returns a String from [member ACTION_CATEGORY_NAMES].
	get:
		return ACTION_CATEGORY_NAMES.get(action_category,"")

#region Requirements
@export var energy_cost: int = 0
var _energy_cost_requirement: ActionRequirementEnergy
@export var is_obstructable: bool ##Will an action be blocked if an actor is on the tile

## A callable must accept `player_data` argument and return a boolean.
@export var requirements: Array[ActionRequirement]

func cast_energy_cost_to_requirement() -> void:
	if energy_cost > 0 && not _energy_cost_requirement:
		## Kind of a HACK but mostly just dunno what way to refactor this.
		## ActionRequirements ideally should be editable in the Inspector,
		## however in that case they must be Resources. This complicates something
		## simple like energy because each thing might want a different quantity and
		## that means having a dozen different resources saved--no reusability without
		## making each one unique. We know most actions will require energy, so
		## to let them operate in the same system I'm casting it to a new ActionRequirement.
		## Probably overthinking this but brain fried atm
		
		_energy_cost_requirement = ActionRequirementEnergy.new()
		_energy_cost_requirement.quantity = energy_cost
		_energy_cost_requirement.ui_display_title = "Energy Cost"
		_energy_cost_requirement.ui_display_description = "Must have enough energy to use this action."
		
		requirements.push_front(_energy_cost_requirement)
		
func can_player_enter(actor: Actor) -> bool:
	cast_energy_cost_to_requirement()
	for requirement: ActionRequirement in requirements:
		if requirement.check(actor) == false:
			if debug: p("Failed requirement check: %s" % requirement)
			return false

		elif debug: p("Passed requirement check: %s" % requirement)

	return true
#endregion


## The actor that will run this action. This is not any "target" such as for dealing damage.
## This data is only populated when the [Actor] runs the action, resulting in [method enter_with] being called.
## A 'queued' action will not have this data populated yet.
var _actor: Actor
func set_actor(actor: Actor) -> void:
	self._actor = actor

## This data is only populated when the [Actor] runs the action, resulting in [method set_target] being called.
## A 'queued' action will not have this data populated yet.
var _target: Variant = null: ## Vector2i absolute
	get:
		if _target == null:
			return _actor.current_tile_coords
		else:
			return _target
			
func set_target(target) -> void:
	if target is Actor:
		_target = target.current_tile_coords
	elif target is Vector2i:
		_target = target
		

## Use to execute actions with an actor.
## It will set the target actor before running [method enter].
func enter_with(actor: Actor, from: Action = null) -> void:
	set_actor(actor)
	enter(from)
	
## Ask the actor's state machine to run this Action
func run_on(actor: Actor) -> void:
	actor.run_action(self)


@warning_ignore("unused_parameter")
func get_targeted_tiles(at_coords: Vector2i, facing: Facing.Cardinal) -> Array[Vector2i]:
	#return Facing.get_target_cells(at_coords, facing, Action.NO_PATTERN)
	return [at_coords] ## same thing
