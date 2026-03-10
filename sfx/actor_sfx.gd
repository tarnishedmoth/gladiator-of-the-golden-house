class_name ActorSfxHandler extends Node2D

signal attack_sound_finished

enum Sounds {
	MOVE,
	ATTACK,
	BLOCK,
	GET_HIT,
}

@onready var move: AudioStreamPlayer2D = $Move
@onready var attack: AudioStreamPlayer2D = $Attack
@onready var block: AudioStreamPlayer2D = $Block
@onready var get_hit: AudioStreamPlayer2D = $GetHit

func _ready() -> void:
	var parent = get_parent()
	if parent is Actor:
		parent.sfx = self
	else:
		push_error("ActorSfxHandler is not a child of an Actor.")
		
func _exit_tree() -> void:
	var parent = get_parent()
	if parent is Actor:
		if parent.sfx == self:
			parent.sfx = null

func play(sound: Sounds) -> void:
	match sound:
		Sounds.MOVE:
			on_move()
		Sounds.ATTACK:
			on_attack()
		Sounds.BLOCK:
			on_block()
		Sounds.GET_HIT:
			on_get_hit()
		_:
			push_error("Out of bounds.")
			
## For future use with different weapon/action sounds perhaps.
func change_attack_sound(stream: AudioStream) -> void:
	attack.stream = stream
	
func on_move() -> void:
	move.play()

func on_attack() -> void:
	if attack.finished.is_connected(attack_sound_finished.emit):
		attack.finished.disconnect(attack_sound_finished.emit)
	attack.finished.connect(attack_sound_finished.emit, ConnectFlags.CONNECT_ONE_SHOT)
	attack.play()

func on_block() -> void:
	block.play()
	
func on_get_hit() -> void:
	get_hit.play()
	
