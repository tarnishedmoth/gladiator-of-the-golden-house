class_name ActionAttack extends Action

@export var damage: int
@export var can_damage_self: bool = false
#@export_category("Target Pattern")
@export var pattern: Array[Vector2i] = [] ## Assume coords 0,0 and facing north. Then list the coords they can hit. the rotate hex function in facing will make that pattern work in any direction.
@export var aoe_pattern: Array[Vector2i]
@export var split_choice: bool = false ## TODO If true, allows for the pattern to *also* apply counter-clockwise. This is specifically for asymmetrical patterns.

## On transition to this state
func enter(from: ResourceState = null) -> void:
	if _actor:
		p("Attacking!")
		
		## run animations etc here
		_actor.play_sfx(ActorSfxHandler.Sounds.ATTACK)
		_get_affected_and_deal_damage()
	else:
		push_error("No actor configured to run action.")
	
	exit()

func _get_affected_and_deal_damage() -> void:
	var targets: Array[Vector2i] = _actor.get_translated_pattern(pattern)

	if debug: p("Targeting %d tiles." % targets.size())

	for coords in targets:
		var found_actor: Actor = Level.get_actor_at(coords)
		
		if found_actor != null:
			if not can_damage_self && found_actor == _actor:
				return
			
			var modified_damage: int = _actor._on_dealing_damage(damage)
			## TODO dealing direct damage check
			var damage_result: Actor.DamageResult = found_actor.take_damage(modified_damage)
			
			if debug: p(
				"Hit %s with %s/%s (base/modified) damage.\n%s damage was negated, %s damage was taken directly." % [found_actor.name, damage, modified_damage, damage_result.negated, damage_result.direct]
				)
			
			_actor._on_damage_dealt(damage_result)
