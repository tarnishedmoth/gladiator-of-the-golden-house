@abstract class_name Status extends Resource

enum StatusEffectCategory{
	NONE,
	DEFENSE,
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

@export var on_start_behavior: OnStart = OnStart.REMOVE_EFFECT

@export var effect_points: int 

@export var ui_name: String 
@export var ui_description: String 
@export var status_effect_category: StatusEffectCategory

#set Actor with Status effect
func set_actor(actor:Actor) -> void:
	self._actor = actor

func on_turn_start() -> void: ## Call super() if you override
	match on_start_behavior:
		OnStart.SUBTRACT_ONE:
			subtract_points(1)
		OnStart.HALVE:
			halve_points()
		OnStart.REMOVE_EFFECT:
			remove_effect()

func on_take_damage(damage:int) -> int: ## Override me
	return damage

func on_deal_damage(damage:int) -> int: ## Override me
	return damage

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
