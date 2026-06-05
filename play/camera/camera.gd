extends Camera2D

const TRACK_MOUSE: bool = true

var axis_ratio: Vector2 = Vector2(0.08, 0.14)
@export var range_limit: Vector2i = Vector2i(960, 540)

@export var use_position_lerp: bool = false ## TODO configurable in user options
@export var lerp_speed: float = 0.01

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var _controlled_follow_factor: float = 0.0

func _ready() -> void:
	animation_player.animation_finished.connect(_on_animation_finished.unbind(1), CONNECT_ONE_SHOT)

@warning_ignore_start("integer_division")
func _process(_delta: float) -> void:
	if TRACK_MOUSE:
		if not animation_player.is_playing():
			#var target = Vector2.ZERO.slerp(get_global_mouse_position() - (get_viewport_rect().size / 2), track_mouse_ratio).clamp(-range_limit/2, range_limit/2)
			var target: Vector2
			target.x = clamp(
				lerp(
					0.0,
					get_global_mouse_position().x - (get_viewport_rect().size.x / 2),
					axis_ratio.x * _controlled_follow_factor),
				-range_limit.x/2, range_limit.x/2)
			target.y = clamp(
				lerp(
					0.0,
					get_global_mouse_position().y - (get_viewport_rect().size.y / 2),
					axis_ratio.y * _controlled_follow_factor),
				-range_limit.y/2, range_limit.y/2)
			
			if use_position_lerp:
				position = position.lerp(target, lerp_speed)
			else:
				position = target

func _on_animation_finished() -> void:
	## Slowly introduce the mouse following camera (avoiding a sudden jerk)
	var control_tween: Tween = create_tween()
	control_tween.tween_property(self, "_controlled_follow_factor", 1.0, Juice.SLOW)
	
	## Reveal the HUD
	var level: Level = Level.instance
	if level:
		if level.hud:
			level.hud.show_hud(true)
