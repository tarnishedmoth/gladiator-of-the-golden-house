class_name ActionAttack extends Action

const DISPLAY_VULN_MULT_POPUP: bool = true

enum VulnerabilityMethods {
	NONE = 0, ## Directional vulnerability is not calculated.
	ACTOR = 1, ## Use the coordinate of the attacking actor.
	TARGET = 2, ## Use the coordinate of the target point, where AoE is placed.
}

enum RefundTypes {
	NONE = 0, ## No energy cost refunds.
	ON_HIT = 1, ## When landing a hit on any enemy (even if damage is negated).
	ON_KILL = 2, ## When having killed the enemy with this attack.
	#PER_DAMAGE_POINT, ## TODO.... maybe
}

@export var damage: int

@export var direct: bool = false ## If true, bypasses any first-layer status effects (Defense).

## Utilize directional damage multipliers on affected actors.
## See [method Actor.calculate_directional_damage_from].
@export var use_directional_vulnerability: VulnerabilityMethods = VulnerabilityMethods.ACTOR

@export var can_damage_self: bool = false
@export var can_damage_teammates: bool = false

## The attack will run this many times when entered.
@export_range(1, 99, 1, "or_greater") var multiple_attacks: int = 1:
	get: return maxi(1, multiple_attacks)

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
			#return NO_PATTERN
			return aoe_pattern
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

@export_group("Refundable Energy Cost")
@export var refundable_cost: RefundTypes = RefundTypes.NONE
@export var refundable_quantity: int = -1 ## If -1, refunds the full [member energy_cost]. Otherwise, this quantity is used.

@export_group("Timing")
## How long to wait after playing FX, before dealing damage. Use for VFX/SFX timing.
@export_range(0.1, 6.0, 0.1) var pre_attack_duration: float = 0.2
## How long to wait after running action, before exiting the action and progressing gameplay. Use for VFX/SFX. This stacks with [member ActionQueue.POST_ACTION_AWAIT_TIME].
@export_range(0.0, 6.0, 0.1) var post_attack_duration: float = 0.0

## On transition to this state
func enter(_from: ResourceState = null) -> void:
	if _actor:
		for i in multiple_attacks:
			p("Attacking!")
			
			## run animations etc here
			_actor.play_sfx(ActorSfxHandler.Sounds.ATTACK)
			_actor.spawn_vfx(ActorVfxHandler.FX.ATTACK)
			await _actor.create_tween().tween_interval(pre_attack_duration).finished
			
			var affected_tiles: Array[Vector2i] = get_affected_tiles()
			var affected_actors: Array[Actor] = get_affected_actors(affected_tiles)
			
			var tiles_with_actors: Array[Vector2i]
			for actor in affected_actors:
				tiles_with_actors.append(actor.current_tile_coords)
			
			## Pass in all valid tiles, and all tiles actually about to be affected
			pulse_affected_tiles(affected_tiles, tiles_with_actors) ## VFX
			
			if not affected_actors.is_empty():
				
				if refundable_cost == RefundTypes.ON_HIT:
					var pts: int = refundable_quantity if refundable_quantity != -1 else energy_cost
					refund(pts)
				
				var modified_damage: int = get_damage()
				_deal_damage(affected_actors,modified_damage)
			else:
				if debug: p("None affected.")
				Level.get_hud().popup_label("Missed", _actor, LevelHUD.STYLE_NEGATED)
			
			if i >= multiple_attacks:
				_actor.clear_incoming_damage_by()
			
			if post_attack_duration > 0.0:
				await _actor.create_tween().tween_interval(post_attack_duration).finished
	else:
		push_error("No actor configured to run action.")
		
	exit()

## old method for compatability with existing scripts
func get_affected() -> Array[Actor]:
	return get_affected_actors(get_affected_tiles())
	
func get_affected_tiles() -> Array[Vector2i]:
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
	return targets

func get_affected_actors(targets: Array[Vector2i]) -> Array[Actor]:
	var affected_actors: Array[Actor]
	
	for coords in targets:
		var found_actor: Actor = Level.get_actor_at(coords)
		if found_actor != null:
			if applies_to_actor(found_actor):
				affected_actors.append(found_actor)
	return affected_actors


func applies_to_actor(actor: Actor) -> bool:
	if not actor: return false
	if not can_damage_self && actor == _actor:
		return false
	if not can_damage_teammates && actor.director == _actor.director:
		return false
	return true


func get_damage() -> int:
	var modified_damage: int = _actor._on_dealing_damage(damage)
	return modified_damage


func _deal_damage(actors:Array[Actor],applied_damage:int) -> void:
	var kills: int = 0
	for actor in actors:
		## Multiply the damage by directional vulnerability
		var _damage: int = do_directional_calculation(actor, applied_damage)
		var _actors_last_health = actor.health
		
		## Tell the actor to take damage.
		## This goes through two layers of status effect hook callbacks,
		## once for regular damage (all damage),
		## and once for direct damage.
		## The result returned is a package of the results after running through all status effects/modifiers.
		var damage_result: Actor.DamageResult
		if not direct:
			damage_result = actor.take_damage(_damage, _actor)
		else:
			damage_result = Actor.DamageResult.new(0, actor.take_direct_damage(_damage, _actor))
		
		if damage_result.direct > 0:
			if damage_result.direct >= _actors_last_health:
				## Got a kill?
				kills += 1
			
			## We dealt direct damage.
			damage_result.direct = _actor._on_dealing_direct_damage(damage_result.direct)
		
		if debug: p(
			"Hit %s with %s/%s (base/modified) damage.\n%s damage was negated, %s damage was taken directly." % [actor.name, damage, _damage, damage_result.negated, damage_result.direct]
				)
		
		_actor._on_damage_dealt(damage_result)
	
	if refundable_cost == RefundTypes.ON_KILL and kills > 0:
		var pts: int = refundable_quantity if refundable_quantity != -1 else energy_cost
		refund(pts)


## See [member use_directional_vulnerability].
func do_directional_calculation(target_actor: Actor, dmg: int) -> int:
	## Directional received damage multiplier
	var _damage: int
	match use_directional_vulnerability:
		VulnerabilityMethods.ACTOR:
			_damage = target_actor.calculate_directional_damage_from(_actor, dmg)
		VulnerabilityMethods.TARGET:
			_damage = target_actor.calculate_directional_damage_from(_target, dmg)
		_:
			_damage = dmg
			
	var calc: float = float(_damage) / dmg
	if DISPLAY_VULN_MULT_POPUP and (not is_zero_approx(calc - 1.0)):
		Level.get_hud().popup_vulnerability(calc, target_actor)
	if debug:
		p("Directional calculation results: %s/%s (base/modified) actual ratio: %s" % [dmg, _damage, calc])
	return _damage
