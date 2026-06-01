class_name ActorVfxHandler extends Node2D

# currently unimplemented:
# signal attack_vfx_finished

enum FX {
	MOVE,
	ATTACK,
	BLOCK,
	GET_HIT,
	TRANSFORM,
}

# scenes to spawn (particle effects)
@export var move: PackedScene
@export var attack: PackedScene
@export var block: PackedScene
@export var get_hit: PackedScene

@export var animation_player: AnimationPlayer
@export var animation_idle: StringName
@export var animation_move: StringName
@export var animation_attack: StringName
@export var animation_block: StringName
@export var animation_get_hit: StringName
@export var animation_transform: StringName
@export var start_as_transformed: bool = false

func _ready() -> void:
	var parent = get_parent()
	if parent is Actor:
		parent.vfx = self
	else:
		push_error("ActorVfxHandler is not a child of an Actor.")
	
	if animation_transform and start_as_transformed:
		play_animation(animation_transform)
	elif animation_idle:
		play_animation(animation_idle)

func _exit_tree() -> void:
	var parent = get_parent()
	if parent is Actor:
		if parent.vfx == self:
			parent.vfx = null

func play(vfx: FX) -> void:
	print("spawning an actor_vfx...")
	match vfx:
		FX.MOVE:
			on_move()
		FX.ATTACK:
			on_attack()
		FX.BLOCK:
			on_block()
		FX.GET_HIT:
			on_get_hit()
		FX.TRANSFORM:
			on_transform()
		_:
			push_error("Out of bounds.")
			
## Pass in a vfx PackedScene, configured in the status effect resource.
func play_status(status_vfx_scene: PackedScene, status: Status) -> void:
	if status_vfx_scene:
		var instance = status_vfx_scene.instantiate()
		instance.global_position = global_position
		
		if instance is StatusEffectParticles:
			if instance.use_effect_points_as_quantity && status.effect_points > 0:
				instance.amount = status.effect_points
		
		get_tree().current_scene.add_child(instance)

func play_animation(string_name: StringName) -> void:
	if animation_player:
		animation_player.play(string_name)

## For future use with different weapon/action sounds perhaps.
func change_attack_vfx(useThisSceneInstead: PackedScene) -> void:
	attack = useThisSceneInstead
	
func on_move() -> void:
	#print("spawning MOVE particles")
	if move:
		var spawnedFX = move.instantiate()
		spawnedFX.global_position = global_position
		# note for this and all other fx below
		# we could spawn as a child of this actor:
		# add_child(spawnedFX) 
		# but choose to spawn on root node so fx persist even if actor is destroyed:
		get_tree().current_scene.add_child(spawnedFX)
	if animation_move:
		play_animation(animation_move)

func on_attack() -> void:
	#print("spawning ATTACK particles")
	# TODO? spawn different particles at beginning and end of an attack
	# (example use: swing "slash" vs hit "sparks" which comes later)
	# if attack.finished.is_connected(attack_sound_finished.emit):
	# 	attack.finished.disconnect(attack_sound_finished.emit)
	# attack.finished.connect(attack_sound_finished.emit, ConnectFlags.CONNECT_ONE_SHOT)
	if attack:
		var spawnedFX = attack.instantiate()
		spawnedFX.global_position = global_position
		# TODO: rotate based on direction of tile we are attacking (not facing)
		get_tree().current_scene.add_child(spawnedFX)
	if animation_attack:
		play_animation(animation_attack)

func on_block() -> void:
	#print("spawning BLOCK particles")
	if block:
		var spawnedFX = block.instantiate()
		spawnedFX.global_position = global_position
		get_tree().current_scene.add_child(spawnedFX)
	if animation_block:
		play_animation(animation_block)
	
func on_get_hit() -> void:
	#print("spawning GET_HIT particles")
	if get_hit:
		var spawnedFX = get_hit.instantiate()
		spawnedFX.global_position = global_position
		get_tree().current_scene.add_child(spawnedFX)
	if animation_get_hit:
		play_animation(animation_get_hit)
	
func on_transform() -> void:
	if animation_transform:
		play_animation(animation_transform)
