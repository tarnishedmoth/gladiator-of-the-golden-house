class_name ActionAttackKnockback extends ActionAttack

## Now with knockback!!!

## Distance to move the actor in the direction vector.
## What we do is calculate the angle and round it to one of the flat directions,
## i.e. knockback will never move an actor to an off-axis coordinate.
@export var distance: int = 1

## If true, attempts to calculate if the affected actor was facing the blast,
## and not apply knockback if so. TODO
@export var only_if_not_facing: bool = false

## i.e. Stunned for being knocked into a wall
@export var status_to_apply_if_knocked_into_obstacle: Status = STUN_STATUS

const STUN_STATUS: StatusStunned = preload("uid://b38qdbmcp8g2n") ## For both Player and AI

## Simplify things for now too much work
#enum DamageRequired {
	#NONE, ## Every affected actor will be knocked back.
	#DAMAGE_DEALT, ## Any damage dealt
	#DIRECT_DAMAGE_DEALT, ## Only direct damage dealt (health affected)
#}
#
#@export var require_damage: DamageRequired = DamageRequired.NONE


func enter(_from: ResourceState = null) -> void:
	if _actor:
		for i in multiple_attacks:
			p("Attacking!")
			
			## run animations etc here
			_actor.play_sfx(ActorSfxHandler.Sounds.ATTACK)
			_actor.spawn_vfx(ActorVfxHandler.FX.ATTACK)
			await _actor.create_tween().tween_interval(pre_attack_duration).finished
			
			var affected_actors: Array[Actor] = get_affected()
			
			if affected_actors.is_empty():
				if debug: p("None affected.")
				Level.get_hud().popup_label("Missed", _actor, LevelHUD.STYLE_NEGATED)
			else:
				var modified_damage: int = get_damage()
				_deal_damage(affected_actors,modified_damage)
				
				if i >= multiple_attacks:
					## Finito
					_actor.clear_incoming_damage_by()
				
				if post_attack_duration > 0.0:
					await _actor.create_tween().tween_interval(post_attack_duration).finished
				
				for affected in affected_actors:
					await knockback(affected)
				
				#match require_damage:
					#DamageRequired.DAMAGE_DEALT:
						#if 
					#DamageRequired.DIRECT_DAMAGE_DEALT:
						#pass
					
			
	else:
		push_error("No actor configured to run action.")
		
	exit()

func knockback(actor: Actor) -> void:
	if debug: p("Knocking back %s..." % actor)
	var direction: Facing.Cardinal
	if actor.current_tile_coords == _actor.current_tile_coords:
		## Impressive
		direction = Facing.get_combined(actor.facing, Facing.Cardinal.SOUTH) ## Back direction
		return
	
	else:
		
		var source_tile: Vector2i
		if use_directional_vulnerability == VulnerabilityMethods.TARGET and _target != actor.current_tile_coords:
			## Calculate from center of AoE
			source_tile = _target
		else:
			## Calculate from actor dealing damage
			source_tile = _actor.current_tile_coords
		direction = Facing.get_direction_to_cell(_actor.tile_map, source_tile, actor.current_tile_coords)
		
		## Move the actor in that direction
		Level.get_hud().popup_status("Knockback", actor)
		var target_tile: Vector2i = actor.current_tile_coords + (Facing.DIRECTIONS[direction] * distance)
		var previous_coords: Vector2i = actor.current_tile_coords
		var result: Vector2i = actor.move_along_path(target_tile)
		
		if debug:
			if actor.previous_tile_coords == result:
				p("Knocked %s into an immediate obstruction." % actor)
			elif result == target_tile:
				p("Knocked %s to %s." % [actor, target_tile])
			else:
				p("Knocked %s to %s where it was halted by an obstruction." % [actor, result])
		
		if result != previous_coords:
			await actor.animation_finished
		
		if result != target_tile:
			## Hit an obstruction
			on_hit_obstruction(actor, direction)
		

func on_hit_obstruction(actor: Actor, direction_of_travel: Facing.Cardinal) -> void:
	if status_to_apply_if_knocked_into_obstacle:
		if debug:
			p("Applying status %s to %s from being knocked into an obstruction." % [status_to_apply_if_knocked_into_obstacle, actor])
		actor.add_status(status_to_apply_if_knocked_into_obstacle)
	
	#Level.get_instance().camera.add_trauma(1.0)
	
	var vr = actor.character_visual_root
	if vr:
		var anim: Tween = actor.create_tween()
		var magnitude = 32
		var angle: float = Facing.get_rad_rotation(direction_of_travel) - deg_to_rad(90)
		var position: Vector2 = Vector2.from_angle(angle) * magnitude
		var starting_pos: Vector2 = vr.position
		p("direction of travel %s, radians %s, target position %s." % [direction_of_travel, angle, position])
		anim.tween_property(vr, "position", vr.position + position, 0.12)
		anim.tween_property(vr, "position", starting_pos, 0.12).set_ease(Tween.EASE_OUT)
