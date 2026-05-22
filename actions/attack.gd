class_name ActionAttack extends Action

@export var damage: int
@export var can_damage_self: bool = false
@export var can_damage_teammates: bool = false
#@export_category("Target Pattern")
@export var pattern: Array[Vector2i] = []: ## Assume coords 0,0 and facing north. Then list the coords they can hit. the rotate hex function in facing will make that pattern work in any direction.
	get:
		if split_choice:
			if run_mirrored:
				if mirrored_pattern.is_empty():
					mirrored_pattern = Facing.mirror(pattern) ## Caching, WARNING does not check equivalency
				return mirrored_pattern
		return pattern

var mirrored_pattern: Array[Vector2i] ## Cached.

@export var aoe_pattern: Array[Vector2i]:
	get:
		if aoe_pattern.is_empty():
			return NO_PATTERN
		if split_choice:
			if run_mirrored:
				if mirrored_aoe_pattern.is_empty():
					mirrored_aoe_pattern = Facing.mirror(aoe_pattern) ## Caching, WARNING does not check equivalency
				return mirrored_aoe_pattern
		return aoe_pattern

var mirrored_aoe_pattern: Array[Vector2i] ## Cached.

## TODO If true, allows for the pattern to *also* apply mirrored (asymmetrical patterns).
## In code, you can mirror a pattern using [method Facing.mirror].
@export var split_choice: bool = false

@export_group("Timing")
## How long to wait after playing FX, before dealing damage. Use for VFX/SFX timing.
@export_range(0.1, 6.0, 0.1) var pre_attack_duration: float = 0.2
## How long to wait after running action, before exiting the action and progressing gameplay. Use for VFX/SFX. This stacks with [member ActionQueue.POST_ACTION_AWAIT_TIME].
@export_range(0.0, 6.0, 0.1) var post_attack_duration: float = 0.0

## On transition to this state
func enter(_from: ResourceState = null) -> void:
	if _actor:
		p("Attacking!")
		
		## run animations etc here
		_actor.play_sfx(ActorSfxHandler.Sounds.ATTACK)
		_actor.spawn_vfx(ActorVfxHandler.FX.ATTACK)
		await _actor.create_tween().tween_interval(pre_attack_duration).finished
		
		var affected_actors: Array[Actor] = get_affected()
		var modified_damage: int = get_damage()
		_deal_damage(affected_actors,modified_damage)
		_actor.clear_incoming_damage_by()
		
		if post_attack_duration > 0.0:
			await _actor.create_tween().tween_interval(post_attack_duration).finished
	else:
		push_error("No actor configured to run action.")
		
	exit()

func get_affected() -> Array[Actor]:
	var affected_actors: Array[Actor]
	var targets: Array[Vector2i]
	var facing: Facing.Cardinal = _actor.get_facing() ## TODO maybe use Facing.get_direction_to_coordinate()
	
	if aoe_pattern && _target != null:
		## Translate our aoe pattern to the _target coordinate
		targets = Facing.get_target_cells(_target, facing, aoe_pattern)
	else:
		## New behavior: only the _target tile
		if _target != null:
			targets.append(_target)
		else:
			## (Old behavior): Every coord relative to _actor
			## We still use this for AI units in some cases, this is good to keep.
			#targets = _actor.get_translated_pattern(pattern)
			targets = _actor.get_action_target_cells(self)

	if debug: p("Targeting %d tiles." % targets.size())
	
	for coords in targets:
		var found_actor: Actor = Level.get_actor_at(coords)
		if found_actor != null:
			if not can_damage_self && found_actor == _actor:
				continue
			if not can_damage_teammates && found_actor.director == _actor.director:
				continue
			affected_actors.append(found_actor)
	return affected_actors

func get_damage() -> int:
	var modified_damage: int = _actor._on_dealing_damage(damage)
	return modified_damage
	
func _deal_damage(actors:Array[Actor],applied_damage:int) -> void:
	for actor in actors:
		var damage_result: Actor.DamageResult = actor.take_damage(applied_damage, _actor)
		if damage_result.direct > 0:
			damage_result.direct = _actor._on_dealing_direct_damage(damage_result.direct)
		if debug: p(
			"Hit %s with %s/%s (base/modified) damage.\n%s damage was negated, %s damage was taken directly." % [actor.name, damage, applied_damage, damage_result.negated, damage_result.direct]
				)
		_actor._on_damage_dealt(damage_result)
		
## DEPRECATED
func _get_affected_and_deal_damage() -> void: #break this into 3 methods get_affected, get_damage, deal_damage
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
