extends OptionButton

func _ready() -> void:
	update()
	Main.instance.game_settings_changed.connect(_on_settings_changed)

func update() -> void:
	self.selected = GameSettings.get_value(GameSettings.SECTION.CAMERA, "mouse_movement", GameSettings.default_camera_mouse_movement)

func _on_settings_changed() -> void:
	update()
