class_name StatusDamageDealt extends Status

enum Operation {
	SUM, ## Add or subtract
	MULTIPLY,
	DIVIDE,
}

@export var factor: float = -1.0
@export var operation: Operation = Operation.SUM

func on_deal_damage(damage: int) -> int:
	var new_damage: float = damage
	match operation:
		Operation.SUM:
			new_damage += factor
		Operation.MULTIPLY:
			new_damage *= factor
		Operation.DIVIDE:
			new_damage /= factor
	return int(new_damage)
