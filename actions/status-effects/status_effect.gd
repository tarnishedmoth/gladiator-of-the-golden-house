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
