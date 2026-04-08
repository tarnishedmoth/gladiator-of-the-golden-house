class_name StatusReturnDamage extends Status

## Deal damage to the offending actor that damaged an actor with this status applied.

## ON_TAKE_DAMAGE or ON_TAKE_DIRECT_DAMAGE only implemented
@export var hook: Hook = Hook.ON_TAKE_DAMAGE

## If false, deals normal damage ([method Actor.take_damage]).
## If true, deals direct damage ([method Actor.take_direct_damage]
@export var deal_direct_damage:  bool = false

## Damage to be dealt on hook.
@export var damage_amount: int = 1

func on_take_damage(damage:int) -> int: ## Override
	if hook == Hook.ON_TAKE_DAMAGE:
		fire()
	return damage
	
func on_take_direct_damage(damage:int) -> int: ## Override
	if hook == Hook.ON_TAKE_DIRECT_DAMAGE:
		fire()
	return damage

func fire() -> void:
	var target = _actor.get_incoming_damage_by()
	
	if target is Actor:
		if not deal_direct_damage:
			#target.take_damage(damage_amount, _actor) ## Not yet warranted by gameplay
			target.take_damage(damage_amount)
		else:
			#target.take_direct_damage(damage_amount, _actor) ## Not yet warranted by gameplay
			target.take_direct_damage(damage_amount)
	else:
		push_warning("Status hooked but no target actor set!")
		
	on_after_hook()
