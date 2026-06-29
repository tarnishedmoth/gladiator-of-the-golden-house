class_name StatusPassAlongDamage extends Status

## Forward a percentage of damage to a target.
## If not using [member target_key], must use [method set_target] to have any effect.

@export var factor: float = 1.0 ## Multiplier to damage to forward.
@export var per_point: bool = false ## Multiplies
@export var direct_only: bool = false

@export var target_key: StringName ## If set, looks for an [Actor] with a matching [member Actor.persistent_data_key].

var target: Actor

func set_target(actor: Actor) -> void:
	target = actor

func do_thing(damage: int) -> void:
	if (not target) and (target_key != null):
		for a in Level.get_all_actors_in_play_order():
			if a.persistent_data_key == target_key:
				set_target(a)
				break
	
	if not target:
		push_warning("No target set up.")
		p("No target set up for StatusPassAlongDamage.")
		return
	
	var damage_to_forward: float = 0
	
	for x in effect_points if per_point else 1:
		damage_to_forward += damage * factor
	
	target.take_damage(ceili(damage_to_forward), _actor.get_incoming_damage_by())


func on_take_damage(damage: int) -> int: ## Override me
	if direct_only:
		return damage
	
	do_thing(damage)
	on_after_hook()
	return damage

func on_take_direct_damage(damage: int) -> int: ## Override me
	if not direct_only:
		return damage
	
	do_thing(damage)
	on_after_hook()
	return damage
