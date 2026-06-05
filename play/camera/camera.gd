class_name LevelCamera extends Camera2D

enum Mode {
	DISABLED = 0,
	DIRECT = 1,
	SMOOTHED = 2,
}

var axis_ratio: Vector2 = Vector2(0.08, 0.14)
var range_limit: Vector2i = Vector2i(960, 540)
var lerp_speed: float = 0.08

@onready var mouse_tracking_mode: Mode = GameSettings.get_value(GameSettings.SECTION.CAMERA, "mouse_movement", GameSettings.default_camera_mouse_movement)

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var _controlled_follow_factor: float = 0.0
var _origin: Vector2 = Vector2.ZERO

func _ready() -> void:
	animation_player.animation_finished.connect(_on_animation_finished.unbind(1), CONNECT_ONE_SHOT)
	Main.instance.game_settings_changed.connect(_on_game_settings_changed)

@warning_ignore_start("integer_division")
func _process(_delta: float) -> void:
	if mouse_tracking_mode == Mode.DISABLED:
		position = _origin
	else:
		if not animation_player.is_playing():
			
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
			
			if mouse_tracking_mode == Mode.SMOOTHED:
				position = position.lerp(target, lerp_speed)
				## diminishing lerp values...

			else:
				position = target

func _on_animation_finished() -> void:
	_origin = position
	## Slowly introduce the mouse following camera (avoiding a sudden jerk)
	var control_tween: Tween = create_tween()
	control_tween.tween_property(self, "_controlled_follow_factor", 1.0, Juice.SLOW).set_ease(Tween.EASE_IN)
	
	## Reveal the HUD
	var level: Level = Level.instance
	if level:
		if level.hud:
			level.hud.show_hud(true)

func _on_game_settings_changed() -> void:
	mouse_tracking_mode = GameSettings.get_value(GameSettings.SECTION.CAMERA, "mouse_movement", GameSettings.default_camera_mouse_movement)
