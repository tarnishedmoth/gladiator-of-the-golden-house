@abstract class_name Status extends Resource

enum StatusEffectCategory{
	NONE,
	DEFENSE,
	REACTION,
}

const STATUS_CATEGORY_ICONS: Dictionary[StatusEffectCategory, Texture2D] = {
	StatusEffectCategory.NONE: preload("uid://disinbamqthvh"),
	StatusEffectCategory.DEFENSE: preload("uid://c7ers5ee7squq"),
	StatusEffectCategory.REACTION: preload("uid://c7ers5ee7squq"),
}

var _actor: Actor
var status_manager: StatusManager:
	get: return _actor.get_status_manager()
	
enum OnStart {
	NOTHING,
	SUBTRACT_ONE,
	HALVE,
	REMOVE_EFFECT,
}

enum Hook {
	ON_TURN_START,
	ON_TURN_END,
	ON_TAKE_DAMAGE,
	ON_TAKE_DIRECT_DAMAGE,
	ON_DEAL_DAMAGE,
	ON_DEAL_DIRECT_DAMAGE,
	ON_DAMAGE_DEALT,
	ON_DIRECT_DAMAGE_DEALT,
	ON_ACTION_PLAYED, ## TODO
}

@export var on_start_behavior: OnStart = OnStart.REMOVE_EFFECT ## Happens when a director's turn begins.
@export var after_hook_behavior: OnStart = OnStart.NOTHING
@export var on_end_behavior: OnStart = OnStart.NOTHING ## Happens when a director's turn ends.
@export var only_react_to_actors_turn_notifs: bool = false ## Affects [member on_start_behavior] and [member on_end_behavior].

@export var effect_points: int 

@export var ui_name: String ## This name is also used as a [member unique_name], for combining statuses when applied.
@export var ui_description: String 
@export var status_effect_category: StatusEffectCategory
@export var ui_icon: Texture2D: ## If left undefined, will use one according to its [member action_category].
	get:
		if ui_icon: return ui_icon
		else: return STATUS_CATEGORY_ICONS.get(status_effect_category)
		
var unique_name: StringName:
	get:
		if not unique_name:
			assert(ui_name, "Status must have a unique name assigned")
			unique_name = ui_name as StringName
		return unique_name
		
static func is_same_status(status_a: Status, status_b: Status) -> bool:
	return status_a.unique_name == status_b.unique_name

#set Actor with Status effect
func set_actor(actor:Actor) -> void:
	self._actor = actor

func on_turn_start() -> void: ## Call super() if you override
	if (not only_react_to_actors_turn_notifs) or (only_react_to_actors_turn_notifs and _actor in Level.get_current_directors_actors()):
		match on_start_behavior:
			OnStart.SUBTRACT_ONE:
				subtract_points(1)
			OnStart.HALVE:
				halve_points()
			OnStart.REMOVE_EFFECT:
				remove_effect()
			
func on_turn_end() -> void: ## Call super() if you override
	if (not only_react_to_actors_turn_notifs) or (only_react_to_actors_turn_notifs and _actor in Level.get_current_directors_actors()):
		match on_end_behavior:
			OnStart.SUBTRACT_ONE:
				subtract_points(1)
			OnStart.HALVE:
				halve_points()
			OnStart.REMOVE_EFFECT:
				remove_effect()
			
func on_after_hook() -> void: ## Call super() if you override
	match after_hook_behavior:
		OnStart.SUBTRACT_ONE:
			subtract_points(1)
		OnStart.HALVE:
			halve_points()
		OnStart.REMOVE_EFFECT:
			remove_effect()

func on_take_damage(damage:int) -> int: ## Override me
	return damage
	
func on_take_direct_damage(damage:int) -> int: ## Override me
	return damage

func on_deal_damage(damage:int) -> int: ## Override me
	return damage
	
func on_deal_direct_damage(damage:int) -> int: ## Override me
	return damage
	
func on_applying_status(new_status: Status) -> Status: ## Override me
	return new_status

@warning_ignore("unused_parameter")
## Happens after damage has been dealt by the actor with this status. The value can not be manipulated. Override me.
func on_damage_dealt(damage:int) -> void:
	pass

@warning_ignore("unused_parameter")
## Happens after damage has been dealt by the actor with this status. The value can not be manipulated. Override me.
func on_direct_damage_dealt(damage:int) -> void:
	pass
	
@warning_ignore("unused_parameter")
## Happens after a status has been applied to the actor with this status.
func on_status_applied(new_status: Status) -> void:
	pass
	#if not is_same_status(self, new_status): #on_after_hook() ## Must be invoked by an extension
		#on_after_hook()

# what do we need to really know about for all possible status effects
# -the actor holding this status effect
# -the actor being targeted by some action
# -all actors in the level -- via Level static instance
# -the tile we're standing on, the tiles in the arena -- via Level static instance

## Common behaviors
func remove_if_empty() -> void:
	if effect_points <= 0:
		remove_effect()

func remove_effect() -> void:
	_actor.remove_status(self)
	
func subtract_points(i: int, and_remove: bool = true) -> void:
	effect_points -= i
	if and_remove:
		remove_if_empty()
		
func add_points(i: int) -> void:
	effect_points += i

func halve_points() -> void:
	if effect_points > 1:
		effect_points = ceili(float(effect_points) / 2.0)
	## If 1, leave it unchanged.
	## If 0 or below, leave it unchanged.

func _to_string() -> String:
	var format: String = "%s(%d)" % [ui_name if ui_name else "NONAME", effect_points]
	return format
