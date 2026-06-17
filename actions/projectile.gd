class_name ActionProjectile extends ActionAttack

## NOTE: Copied a bit of code from the [ActionAttack] class.
## Intent is to support shooting or tossing of sprites to a target tile (just different animations)
## and do something depending on what's there.

enum VfxBehavior {
	CENTER = 0, ## Spawns just one instance on the _target tile.
	WITH_ACTORS = 1, ## Spawns one instance on each tile occupied by an actor.
	ALL = 2, ## Spawns an instance on every tile in the [member aoe_pattern].
}

enum VfxShown {
	ALWAYS, ## Always spawned.
	ACTORS_AFFECTED, ## Shown only when an actor is affected.
}

@export var projectile_scene: PackedScene ## This can be just a sprite, or anything. No functionality necessary
@export var speed: float = 128.0 ## Pixels per second
@export var arc: float = 0.0

@export var rotate_to_direction: bool = false ## If true, uses the scene's X+ (RIGHT) direction for forward.

@export var hit_vfx_scene: PackedScene ## Spawned when the projectile hits an actor. Must manage its own freedom (queue_free lol).
@export var hit_vfx_shown: VfxShown
@export var hit_vfx_behavior: VfxBehavior = VfxBehavior.CENTER
@export var deploy_scene: PackedScene ## Spawned only when the projectile does NOT hit an actor. Must manage its own freedom (queue_free lol).

var _finito: bool = false

func enter(_from: ResourceState = null) -> void:
	if (_target == null) or (not _actor):
		push_error("Missing setup")
		exit()
		return
		
	if not TileInteractor.cell_exists(_target, _actor.tile_map):
		## Invalid target tile--early exit
		await _actor.create_tween().tween_interval(0.25).finished
		exit()
		return
	
	p("Projectiling!")
	
	## run animations etc here
	_actor.play_sfx(ActorSfxHandler.Sounds.ATTACK)
	_actor.spawn_vfx(ActorVfxHandler.FX.ATTACK)
	await _actor.create_tween().tween_interval(pre_attack_duration).finished
	
	## projectile
	var facing: Facing.Cardinal = _actor.get_facing() ## TODO FIXME use Facing.get_direction_to_coordinate()
	
	if projectile_scene:
		if projectile_scene.can_instantiate():
			var projectile: Node2D = projectile_scene.instantiate()
			_actor.tile_map.add_child(projectile)
			projectile.global_position = _actor.global_position
			
			var target_gp: Vector2 = Actor.get_global_position_at(_actor.tile_map, _target)
			var distance: float = _actor.global_position.distance_to(target_gp)
			var duration: float = distance / speed
			
			if rotate_to_direction:
				projectile.rotate(Facing.get_rad_rotation(facing))
			
			var x_move: Tween = projectile.create_tween()
			var y_move: Tween = projectile.create_tween()
			x_move.tween_property(projectile, ^"global_position:x", target_gp.x, duration).set_trans(Tween.TRANS_LINEAR)
			
			if is_zero_approx(arc):
				y_move.tween_property(projectile, ^"global_position:y", target_gp.y, duration)#.set_trans(Tween.TRANS_CIRC)
			else:
				var arc_midpoint: Vector2 = _actor.global_position.lerp(target_gp, 0.5)
				y_move.tween_property(projectile, ^"global_position:y", arc_midpoint.y - arc, duration/2.0).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
				y_move.tween_property(projectile, ^"global_position:y", target_gp.y, duration/2.0).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN)
			
			x_move.tween_callback(_on_projectile_finito)
			x_move.tween_callback(projectile.queue_free)
			return
	## Failsafe should never run
	_on_projectile_finito()


func _on_projectile_finito() -> void:
	if _finito: return
	_finito = true
	
	if hit_vfx_shown == VfxShown.ALWAYS:
		_spawn_hit_vfxs()
	
	var affected_tiles: Array[Vector2i] = get_affected_tiles()
	pulse_affected_tiles(affected_tiles) ## VFX
	
	var affected_actors: Array[Actor] = get_affected_actors(affected_tiles)
	if not affected_actors.is_empty():
		## Hit an actor
		
		## VFX
		if hit_vfx_shown == VfxShown.ACTORS_AFFECTED:
			_spawn_hit_vfxs()
		
		## Damage
		var modified_damage: int = get_damage()
		_deal_damage(affected_actors, modified_damage)
		_actor.clear_incoming_damage_by()
		
	else:
		## Deploy scene, if applicable
		if deploy_scene:
			if deploy_scene.can_instantiate():
				var deployment: Node2D = deploy_scene.instantiate()
				## TODO any necessary setup for the deploy scene.
				## We need to support spawning Actors as well as Pick Ups, and also Traps eventually.
				Level.get_base_tile_map_layer().add_child(deployment)
				deployment.global_position = Actor.get_global_position_at(_actor.tile_map, _target)
	
	if post_attack_duration > 0.0:
		await _actor.create_tween().tween_interval(post_attack_duration).finished
		
	exit()
	
func _spawn_hit_vfxs() -> void:
	if not hit_vfx_scene:
		return
	if not hit_vfx_scene.can_instantiate():
		return
		
	if hit_vfx_behavior == VfxBehavior.CENTER:
		_spawn_hit_vfx_at(_target)
	elif aoe_pattern and not aoe_pattern.is_empty():
			var facing: Facing.Cardinal = _actor.get_facing()
			var _aoe_targets: Array[Vector2i] = Facing.get_target_cells(_target, facing, aoe_pattern)
			for coord in _aoe_targets:
				if hit_vfx_behavior == VfxBehavior.WITH_ACTORS:
					if not Level.get_actor_at(coord):
						continue
				_spawn_hit_vfx_at(coord)
	else:
		_spawn_hit_vfx_at(_target)

func _spawn_hit_vfx_at(coord: Vector2i) -> void: ## Absolute coord
	var vfx: Node2D = hit_vfx_scene.instantiate()
	_actor.tile_map.add_child(vfx)
	vfx.global_position = Actor.get_global_position_at(_actor.tile_map, coord)
