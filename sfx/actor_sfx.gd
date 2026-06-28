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
	STANCE_CHANGE,
}

## If any of these fields are assigned, it will be passed into the audio player on ready.
@export_group("Overrides", "override_")
@export var override_move: AudioStream
@export var override_attack: AudioStream
@export var override_block: AudioStream
@export var override_block_broken: AudioStream
@export var override_get_hit: AudioStream
@export var override_get_hit_critical: AudioStream
@export var override_buff: AudioStream
@export var override_debuff: AudioStream
@export var override_stance_change: AudioStream

@onready var move: AudioStreamPlayer2D = $Move
@onready var attack: AudioStreamPlayer2D = $Attack
@onready var block: AudioStreamPlayer2D = $Block
@onready var block_broken: AudioStreamPlayer2D = $BlockBroken
@onready var get_hit: AudioStreamPlayer2D = $GetHit
@onready var get_hit_critical: AudioStreamPlayer2D = $GetHitCritical
@onready var buff: AudioStreamPlayer2D = $Buff
@onready var debuff: AudioStreamPlayer2D = $Debuff
@onready var stance_change: AudioStreamPlayer2D = $StanceChange

func _ready() -> void:
	override_streams_in_players()
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


func override_streams_in_players() -> void:
	if override_move: move.stream = override_move
	if override_attack: attack.stream = override_attack
	if override_block: block.stream = override_block
	if override_block_broken: block_broken.stream = override_block_broken
	if override_get_hit: get_hit.stream = override_get_hit
	if override_get_hit_critical: get_hit.stream = override_get_hit_critical
	if override_buff: buff.stream = override_buff
	if override_debuff: debuff.stream = override_debuff
	if override_stance_change: stance_change.stream = override_stance_change

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
		Sounds.STANCE_CHANGE:
			on_stance_change()
		_:
			pass

## For future use with different weapon/action sounds perhaps.
func change_attack_sound(stream: AudioStream) -> void:
	attack.stream = stream
	
var oneshot_cache: Dictionary[AudioStream, AudioStreamPlayer2D] = {}
## instantiate a temporary 2D player and play the audio oneshot
func play_oneshot(stream: AudioStream, global_pos: Vector2) -> void:
	var tp: AudioStreamPlayer2D
	if not stream in oneshot_cache:
		tp = AudioStreamPlayer2D.new()
		tp.stream = stream
		add_child(tp)
		oneshot_cache[stream] = tp
	else:
		tp = oneshot_cache[stream]
	
	tp.global_position = global_pos
	tp.play()

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
	
func on_stance_change() -> void:
	stance_change.play()

const DEBOUNCE_TIME: float = 0.0167 # ha
var _debouncer: Tween
func _debouncing() -> bool:
	if _debouncer:
		if _debouncer.is_running():
			return true
	_debouncer = create_tween()
	_debouncer.tween_interval(DEBOUNCE_TIME)
	return false
