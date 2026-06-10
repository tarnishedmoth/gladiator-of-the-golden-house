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
@export var expend_points_against_damage: bool = false ## If true, points are reduced 1:1 with modified damage.

@export_group("Directional Behavior")
## If true, will apply these multipliers to the effectiveness of this status for each direction.
@export var use_directional: bool = false
@export var dir_f: float = 1.0
@export var dir_fr: float = 1.0
@export var dir_rr: float = 1.0
@export var dir_r: float = 1.0
@export var dir_rl: float = 1.0
@export var dir_fl: float = 1.0

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
	
	var _factor: float = factor
	if use_directional:
		if incoming_or_outgoing == DamageHook.DEALING:
			## TODO not implemented for dealing damage??? Dunno if that's useful.
			pass
		else:
			var _source = _actor.get_incoming_damage_by()
			var _multiplier: float = 1.0
			if _source:
				var direction: Facing.Relative = _actor.get_incoming_damage_face(_source) ## HACK technically a mismatch with AoE style attacks, watch for bugs.
				match direction:
					Facing.Relative.FRONT:
						_multiplier = dir_f
					Facing.Relative.FRONT_RIGHT:
						_multiplier = dir_fr
					Facing.Relative.BACK_RIGHT:
						_multiplier = dir_rr
					Facing.Relative.BACK:
						_multiplier = dir_r
					Facing.Relative.BACK_LEFT:
						_multiplier = dir_rl
					Facing.Relative.FRONT_LEFT:
						_multiplier = dir_fl
				_factor *= _multiplier
				if debug:
					p("Factor %s/%s (base/modified) - %s directional multiplier in the %s direction." % [factor, _factor, _multiplier, direction])
	
	match operation:
		Operation.SUM:
			new_damage += _factor if not per_point else _factor * effect_points
		Operation.MULTIPLY:
			## NOTE Bad idea to use this with per-point
			new_damage *= _factor if not per_point else _factor * effect_points
		Operation.DIVIDE:
			## NOTE Bad idea to use this with per-point
			new_damage /= _factor if not per_point else _factor * effect_points
	
	new_damage = maxf(0.0, new_damage)
	
	if debug:
		p("%s/%s (base/modified) damage (%sx) EP %s." % [damage, new_damage, float(new_damage)/damage, effect_points])
	
	if expend_points_against_damage:
		if use_directional:
			if not is_zero_approx(_factor):
				effect_points -= damage
		else:
			effect_points -= damage
		
		
		if effect_points >= 0:
			on_after_hook(true) ## Successful sound effect
		else:
			remove_effect()
			on_after_hook(false) ## Status broken sound effect
	
	else:
		on_after_hook()
	
	return int(new_damage)
