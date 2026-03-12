extends Camera2D

const TRACK_MOUSE: bool = true
@export var track_mouse_ratio: float = 0.12

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _process(delta: float) -> void:
	if TRACK_MOUSE:
		if not animation_player.is_playing():
			position = Vector2.ZERO.slerp(get_global_mouse_position() - (get_viewport_rect().size / 2), track_mouse_ratio)
