extends Camera2D

const TRACK_MOUSE: bool = true
@export var axis_ratio: Vector2 = Vector2(0.05, 0.05)
@export var lerp_speed: float = 0.01
@export var range_limit: Vector2i = Vector2i(960, 540)

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _process(delta: float) -> void:
	if TRACK_MOUSE:
		if not animation_player.is_playing():
			#var target = Vector2.ZERO.slerp(get_global_mouse_position() - (get_viewport_rect().size / 2), track_mouse_ratio).clamp(-range_limit/2, range_limit/2)
			var target: Vector2
			target.x = clamp(lerp(0.0, get_global_mouse_position().x - (get_viewport_rect().size.x / 2), axis_ratio.x), -range_limit.x/2, range_limit.x/2)
			target.y = clamp(lerp(0.0, get_global_mouse_position().y - (get_viewport_rect().size.y / 2), axis_ratio.y), -range_limit.y/2, range_limit.y/2)
			position = position.lerp(target, lerp_speed)
			#position = position.lerp(get_global_mouse_position() - (get_viewport_rect().size / 2), 0.01).clamp(-range_limit/2, range_limit/2)
