class_name StatusReactApplyStatus extends Status

## Applies a status effect to a target during a hook callback.

enum BasicTargets {
	SELF,
	DAMAGE_IN_OR_OUT, ## The actor who is damaging us, or who we are damaging.
}

@export var status_to_apply: Status
@export var override_quantity_to_apply: int = 0 ## must be greater than zero to have an affect
@export var get_quantity_from_damage_dealt: bool = false ## If true, will apply equal status points as damage dealt, according to [member trigger].
@export var trigger: Hook = Hook.ON_TAKE_DAMAGE
@export var target_actor: BasicTargets

var target: Actor

func set_target(actor: Actor) -> void:
	target = actor
	
func get_target() -> Actor:
	if target:
		return target
	else:
		match target_actor:
			BasicTargets.SELF:
				return _actor
			BasicTargets.DAMAGE_IN_OR_OUT:
				push_error("Not yet implemented!")
				## TODO
		return null
		
func set_override_quantity(i:int) -> void:
	override_quantity_to_apply = i


func on_turn_start() -> void:
	if trigger == Hook.ON_TURN_START:
		apply_status()
	super()
	
func on_turn_end() -> void:
	if trigger == Hook.ON_TURN_END:
		apply_status()
	super()
	
func on_take_damage(damage:int) -> int:
	if trigger == Hook.ON_TAKE_DAMAGE:
		apply_status(override_quantity_to_apply if not get_quantity_from_damage_dealt else damage)
	return damage
	
func on_take_direct_damage(damage:int) -> int:
	if trigger == Hook.ON_TAKE_DIRECT_DAMAGE:
		apply_status(override_quantity_to_apply if not get_quantity_from_damage_dealt else damage)
	return damage
	
func on_deal_damage(damage:int) -> int:
	if trigger == Hook.ON_DEAL_DAMAGE:
		apply_status(override_quantity_to_apply if not get_quantity_from_damage_dealt else damage)
	return damage
	
func on_deal_direct_damage(damage:int) -> int:
	if trigger == Hook.ON_DEAL_DIRECT_DAMAGE:
		apply_status(override_quantity_to_apply if not get_quantity_from_damage_dealt else damage)
	return damage
	
func on_damage_dealt(damage:int) -> void:
	if trigger == Hook.ON_DAMAGE_DEALT:
		apply_status(override_quantity_to_apply if not get_quantity_from_damage_dealt else damage)

func on_direct_damage_dealt(damage:int) -> void:
	if trigger == Hook.ON_DIRECT_DAMAGE_DEALT:
		apply_status(override_quantity_to_apply if not get_quantity_from_damage_dealt else damage)

func apply_status(override_quantity: int = override_quantity_to_apply) -> void:
	if not status_to_apply:
		push_error("Null configuration")
	else:
		StatusManager.apply_status_to_actor(
			status_to_apply,
			get_target(),
			override_quantity
			)
