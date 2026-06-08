@abstract class_name Action extends ResourceState

const NO_PATTERN: Array[Vector2i] = [Vector2i(0,0)] ## Empty value used for targeting logic.
@export var allow_facing_before: bool
@export var allow_facing_after: bool
var run_mirrored: bool = false ## see split choice in [ActionAttack]

enum ActionCategory{
	COMBAT = 0,
	MOVEMENT = 1,
	SKILL = 2,
	CONSUMABLE = 3,
	SPECIAL = 4,
	CHANGE_STANCE = 5,
}

const ACTION_CATEGORY_NAMES = {
	ActionCategory.MOVEMENT:"Movement",
	ActionCategory.COMBAT: "Combat",
	ActionCategory.SKILL: "Skill",
	ActionCategory.CONSUMABLE: "Consumable",
	ActionCategory.SPECIAL: "Special",
	ActionCategory.CHANGE_STANCE: "Change Stance",
}

const ACTION_CATEGORY_ICONS: Dictionary[ActionCategory, Texture2D] = {
	ActionCategory.MOVEMENT: preload("uid://di4of536vet0h"),
	ActionCategory.COMBAT: preload("uid://c7ers5ee7squq"),
	ActionCategory.SKILL: preload("uid://d3xi5wfi8m2c8"),
	ActionCategory.CONSUMABLE: preload("uid://y7cl8xvqff14"),
	ActionCategory.SPECIAL: preload("uid://djkuqh38qkm5l"),
	ActionCategory.CHANGE_STANCE: preload("uid://c8q1l70wfws3p"),
}

static func get_action_color(action: Action) -> Color:
	if action is ActionMove:
		return Targeting.COLORS.BLUE
	elif action is ActionApplyStatus:
		return Targeting.COLORS.YELLOW
	elif action is ActionChangeStance:
		return Targeting.COLORS.YELLOW
	else:
		return Targeting.COLORS.RED

#@export_group("UI")
@export var ui_title: String ## Displayed in the Actions list

## Displayed when hovering over an action.
## NOTE the following actions will append some information to the description procedurally:
## Apply Status (status effect UI name and description).
@export_multiline() var ui_description: String
@export var ui_icon: Texture2D: ## If left undefined, will use one according to its [member action_category].
	get:
		if ui_icon: return ui_icon
		else: return ACTION_CATEGORY_ICONS.get(action_category)
@export var action_category: ActionCategory ## See also [member ui_category].
var ui_category: String: ## Returns a String from [member ACTION_CATEGORY_NAMES].
	get:
		return ACTION_CATEGORY_NAMES.get(action_category,"")


#region Energy Cost
#@export_group("Requirements")
@export var energy_cost: int = 0:
	get:
		if _actor:
			var director = _actor.director as Player
			if director:
				return energy_cost + director.addtl_energy_cost
		return energy_cost
				
var _energy_cost_requirement: ActionRequirementEnergy
@export var is_obstructable: bool ##Will an action be blocked if an actor is on the tile

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
#endregion

## A callable must accept `player_data` argument and return a boolean.
## Consider populating the requirements array in _init, or _enter_tree.
@export var requirements: Array[ActionRequirement]

var _actor: Actor ## The actor that will run this action. This is not any "target" such as for dealing damage.
func set_actor(actor: Actor) -> void:
	self._actor = actor
	
var _target: Variant = null ## Vector2i absolute

func set_target(target) -> void:
	if target is Actor:
		_target = target.current_tile_coords
	elif target is Vector2i:
		_target = target

func can_player_enter(actor: Actor, quiet: bool = false) -> bool:
	cast_energy_cost_to_requirement()
	for requirement: ActionRequirement in requirements:
		if requirement.check(actor) == false:
			if debug && !quiet: p("Failed requirement check: %s" % requirement)
			return false

		elif debug && !quiet: p("Passed requirement check: %s" % requirement)

	return true

## Use to execute actions with an actor.
## It will set the target actor before running [method enter].
func enter_with(actor: Actor, from: Action = null) -> void:
	set_actor(actor)
	enter(from)
	
## Ask the actor's state machine to run this Action
func run_on(actor: Actor) -> void:
	actor.run_action(self)

func exit() -> void:
	if _target != null && next_state:
		next_state.set_target(_target)
	super()


func refund(energy_points: int) -> void:
	if not _actor:
		return
	if debug: p("Refunding %d energy cost to %s." % [energy_points, _actor])
	_actor.add_energy(energy_points)

## NOTICE NOT IMPLEMENTED
## NOTICE NOT IMPLEMENTED
## Each property is in absolute coordinates!
class ImplicatedTiles:
	var source: Vector2i ## To clearly show where the action's actor is
	var playable: Array[Vector2i] ## Playable tiles for this action. AoE would be translated to this tile.
	var effected: Array[Vector2i] ## Tiles where the action effect will be applied.
	#var blocked: Array[Vector2i] ## Tiles where the action effect can not be applied.
	#var blockers: Array[Vector2i] ## Actor on tile. Not the same as an actor who would take damage.

## NOTICE NOT IMPLEMENTED
## NOTICE NOT IMPLEMENTED
func get_implicated_tiles(_at_coords: Vector2i) -> ImplicatedTiles:
	var tiles := ImplicatedTiles.new()
	tiles.source = _actor.current_tile_coords
	#tiles.playable = Facing.get_target_cells(_actor.current_tile_coords, _actor.facing, pattern)
	## TODO
	return tiles


#region Save / Load

## Stash entries are template references with no per-card runtime state today.
## from_dict() returns a duplicate so future per-card mutable state will not silently leak.
## If you add per-card runtime state, capture it here too.
func to_dict() -> Dictionary:
	var uid_text := SaveUid.resolve(self)
	assert(uid_text != "", "Action %s has no UID — must originate from a .tres asset (resource_path=%s)." % [self, resource_path])
	return { "uid": uid_text }

## Returns null on UID-load failure (renamed/deleted .tres) — callers should retain the original dict
## to round-trip unresolved entries.
static func from_dict(d: Dictionary) -> Action:
	var uid_text: String = d.get("uid", "")
	if uid_text == "":
		push_warning("Action.from_dict: missing 'uid' key")
		return null
	var uid_id := ResourceUID.text_to_id(uid_text)
	if uid_id == ResourceUID.INVALID_ID or not ResourceUID.has_id(uid_id):
		push_warning("Action.from_dict: unresolvable UID %s" % uid_text)
		return null
	var template := load(ResourceUID.get_id_path(uid_id)) as Action
	if not template:
		push_warning("Action.from_dict: failed to load %s" % uid_text)
		return null
	var instance := template.duplicate(true) as Action
	SaveUid.tag_duplicate(template, instance)
	return instance

#endregion

func _to_string() -> String:
	return ui_title if ui_title else resource_name
