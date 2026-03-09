class_name StatusAffectDamage extends Status

enum Operation {
	SUM, ## Add or subtract
	MULTIPLY,
	DIVIDE,
}

enum DamageHook {
	DEALING,
	RECEIVING,
}

@export var incoming_or_outgoing: DamageHook = DamageHook.DEALING ## Pick the appropriate scenario
@export var direct_only: bool = false

@export var factor: float = -1.0
@export var operation: Operation = Operation.SUM
@export var per_point: bool = true ## NOTE Don't use this with multiply or divide unless you know what you're doing.

@export var expend_points_when_applied: bool = false


func on_deal_damage(damage: int) -> int:
	if (not incoming_or_outgoing == DamageHook.DEALING) or direct_only:
		return super(damage)
	else:
		return modify_damage(damage)

func on_deal_direct_damage(damage: int) -> int:
	if (not incoming_or_outgoing == DamageHook.DEALING) or not direct_only:
		return super(damage)
	else:
		return modify_damage(damage)
		
func on_take_damage(damage: int) -> int:
	if (not incoming_or_outgoing == DamageHook.RECEIVING) or direct_only:
		return super(damage)
	else:
		return modify_damage(damage)

func on_take_direct_damage(damage: int) -> int:
	if (not incoming_or_outgoing == DamageHook.RECEIVING) or not direct_only:
		return super(damage)
	else:
		return modify_damage(damage)


func modify_damage(damage:int) -> int:
	var new_damage: float = damage
	match operation:
		Operation.SUM:
			new_damage += factor if not per_point else factor * effect_points
		Operation.MULTIPLY:
			## NOTE Bad idea to use this with per-point
			new_damage *= factor if not per_point else factor * effect_points
		Operation.DIVIDE:
			## NOTE Bad idea to use this with per-point
			new_damage /= factor if not per_point else factor * effect_points
	
	if expend_points_when_applied:
		pass
	
	return int(new_damage)
