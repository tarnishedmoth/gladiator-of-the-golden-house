class_name StatusDamageDealt extends Status

enum Operation {
	SUM, ## Add or subtract
	MULTIPLY,
	DIVIDE,
}

@export var factor: float = -1.0
@export var operation: Operation = Operation.SUM
@export var per_point: bool = true ## NOTE Don't use this with multiply or divide unless you know what you're doing.

func on_deal_damage(damage: int) -> int:
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
	return int(new_damage)
