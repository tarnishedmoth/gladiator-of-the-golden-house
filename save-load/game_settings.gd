class_name GameSettings

## Stores player preferences and game settings.

const CONFIG_FILEPATH: String = "user://game_config.ini"

static var instance: ConfigFile:
	get:
		if not instance:
			load_config()
		return instance

static func p(args): print_rich("[color=green]GameSettings: ", args)

#region Settings variables
const SECTION = {
	GRAPHICS = "graphics",
	SAVES = "saves",
	CAMERA = "camera",
	COMPLETIONS = "completions"
}

static var default_graphics: Dictionary = {
	windowed = 0, ## Windowed. See window.gd
	resolution_x = ProjectSettings.get_setting("display/window/size/viewport_width"),
	resolution_y = ProjectSettings.get_setting("display/window/size/viewport_height"),
	ui_scaling = ProjectSettings.get_setting("display/window/stretch/scale"),
	
	fps_limiter_enabled = false,
	fps_limit = 60,
	vsync = ProjectSettings.get_setting("display/window/vsync/vsync_mode"),
	
}

const default_camera_mouse_movement: LevelCamera.Mode = LevelCamera.Mode.DIRECT

enum Qualities3 {
	LOW,
	HIGH, ## typically default
	ULTRA,
}

#endregion

## Some settings might be saved in the profile save slot rather than a ConfigFile.
## then subscribe to SaveLoad...
#func capture_save_data() -> Dictionary:
	#var d: Dictionary = {}
	#
	#save_config()
	#return d
	#
#func apply_save_data(save: SaveLoad.LoadedSave) -> void:
	### IDK
	#pass

static func default_config() -> void:
	p("defaulting config.")
	instance = ConfigFile.new()
	
	instance.set_value(SECTION.COMPLETIONS, "game_completed", false)
	
	## Graphics
	for key in default_graphics:
		instance.set_value(SECTION.GRAPHICS, key, default_graphics[key])
	
	## camera
	instance.set_value(SECTION.CAMERA, "mouse_movement", default_camera_mouse_movement)
	
	_on_game_settings_changed()

static func save_config() -> void:
	SaveLoad.check_and_create_directory(CONFIG_FILEPATH.get_base_dir())
	instance.save(CONFIG_FILEPATH)

static func load_config() -> void:
	if not FileAccess.file_exists(CONFIG_FILEPATH):
		default_config()
		
	else:
	
		p("parsing config...")
		var config := ConfigFile.new()
		var error: Error = config.load(CONFIG_FILEPATH)
		
		if not error == Error.OK:
			p("parse failed--is config corrupt?")
		else:
			instance = config
			_on_game_settings_changed()

static func get_value(section: String, key: String, default = null) -> Variant:
	var value
	if default != null:
		value = instance.get_value(section, key, default)
	elif section == "graphics":
		value = instance.get_value(section, key, default_graphics.get(key))
	else:
		value = instance.get_value(section, key)
	return value

static func set_value(section: String, key: String, value: Variant) -> void:
	instance.set_value(section, key, value)
	_on_game_settings_changed()

static func _on_game_settings_changed() -> void:
	if Main.instance:
		Main.instance.game_settings_changed.emit()
