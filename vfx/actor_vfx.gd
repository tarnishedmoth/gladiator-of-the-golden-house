class_name ActorVfxHandler extends Node2D

# currently unimplemented:
# signal attack_vfx_finished

enum FX {
	MOVE,
	ATTACK,
	BLOCK,
	GET_HIT,
}

# scenes to spawn (particle effects)
@export var move: PackedScene
@export var attack: PackedScene
@export var block: PackedScene
@export var get_hit: PackedScene

func _ready() -> void:
	var parent = get_parent()
	if parent is Actor:
		parent.vfx = self
	else:
		push_error("ActorVfxHandler is not a child of an Actor.")
		
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
		_:
			push_error("Out of bounds.")
			
## For future use with different weapon/action sounds perhaps.
func change_attack_vfx(useThisSceneInstead: PackedScene) -> void:
	attack = useThisSceneInstead
	
func on_move() -> void:
	print("spawning MOVE particles")
	if move:
		var spawnedFX = move.instantiate()
		spawnedFX.global_position = global_position
		# note for this and all other fx below
		# we could spawn as a child of this actor:
		# add_child(spawnedFX) 
		# but choose to spawn on root node so fx persist even if actor is destroyed:
		get_tree().current_scene.add_child(spawnedFX) 

func on_attack() -> void:
	print("spawning ATTACK particles")
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

func on_block() -> void:
	print("spawning BLOCK particles")
	if block:
		var spawnedFX = block.instantiate()
		spawnedFX.global_position = global_position
		get_tree().current_scene.add_child(spawnedFX) 
	
func on_get_hit() -> void:
	print("spawning GET_HIT particles")
	if get_hit:
		var spawnedFX = get_hit.instantiate()
		spawnedFX.global_position = global_position
		get_tree().current_scene.add_child(spawnedFX) 
	
