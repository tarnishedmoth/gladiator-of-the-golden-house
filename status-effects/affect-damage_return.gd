class_name StatusAffectDamageReturn extends StatusAffectDamagePoised

## EXPERIMENTAL
## Designed to be use in reducing incoming damage scenarios only

@export var damage_amount: int = -1 ## If < 0, will return damage up to total received, after defending. Otherwise, fixed.
@export var deal_direct_damage: bool = false


func modify_damage(damage:int) -> int:
	var incoming: int = damage
	var after_defense: int = super(damage)
	
	if after_defense < incoming:
		## Whether this is 0 or something below incoming it will work
		deal_damage_to_offender(incoming - after_defense)
	
	return after_defense

func deal_damage_to_offender(amount: int) -> void:
	var target = _actor.get_incoming_damage_by()
	
	if target is Actor:
		if not deal_direct_damage:
			#target.take_damage(damage_amount, _actor) ## Not yet warranted by gameplay
			target.take_damage(amount if damage_amount < 0 else damage_amount)
		else:
			#target.take_direct_damage(damage_amount, _actor) ## Not yet warranted by gameplay
			target.take_direct_damage(amount if damage_amount < 0 else damage_amount)
	else:
		push_warning("StatusReturnDamage hooked but no target actor set!")
