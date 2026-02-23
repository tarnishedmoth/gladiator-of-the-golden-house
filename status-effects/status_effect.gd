@abstract class_name Status extends Resource

enum StatusEffectCategory{
	NONE,
	DEFENSE,
}

var _actor: Actor

@export var effect_points: int 

@export var ui_name: String 
@export var ui_description: String 
@export var status_effect_category: StatusEffectCategory

#set Actor with Status effect
func set_actor(actor:Actor) -> void:
	self._actor = actor

func on_turn_start() -> void:
	pass

func on_take_damage(damage:int) -> int:
	var newDamage: int = damage
	return newDamage

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
