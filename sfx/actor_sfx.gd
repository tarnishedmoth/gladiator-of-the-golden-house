class_name ActorSfxHandler extends Node2D

signal attack_sound_finished

enum Sounds {
	NONE,
	MOVE,
	ATTACK,
	BLOCK,
	BLOCK_BROKEN,
	GET_HIT,
	GET_HIT_CRITICAL,
	BUFF,
	DEBUFF,
}

@onready var move: AudioStreamPlayer2D = $Move
@onready var attack: AudioStreamPlayer2D = $Attack
@onready var block: AudioStreamPlayer2D = $Block
@onready var block_broken: AudioStreamPlayer2D = $BlockBroken
@onready var get_hit: AudioStreamPlayer2D = $GetHit
@onready var get_hit_critical: AudioStreamPlayer2D = $GetHitCritical
@onready var buff: AudioStreamPlayer2D = $Buff
@onready var debuff: AudioStreamPlayer2D = $Debuff

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
		Sounds.BLOCK_BROKEN:
			on_block_broken()
		Sounds.GET_HIT:
			on_get_hit()
		Sounds.GET_HIT_CRITICAL:
			on_get_hit_critical()
		Sounds.BUFF:
			on_buff()
		Sounds.DEBUFF:
			on_debuff()
		_:
			pass
			
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

func on_block_broken() -> void:
	block_broken.play()
	
func on_get_hit() -> void:
	if not _debouncing():
		get_hit.play()

func on_get_hit_critical() -> void:
	get_hit_critical.play()
	
func on_buff() -> void:
	buff.play()
	
func on_debuff() -> void:
	debuff.play()

const DEBOUNCE_TIME: float = 0.0167 # ha
var _debouncer: Tween
func _debouncing() -> bool:
	if _debouncer:
		if _debouncer.is_running():
			return true
	_debouncer = create_tween()
	_debouncer.tween_interval(DEBOUNCE_TIME)
	return false
