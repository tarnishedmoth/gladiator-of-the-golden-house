class_name Main extends Node

## Perform any initialization steps,
## Skip to the Developer Main Menu, or
## Load the splash,
## then load the main menu.

signal game_settings_changed

static var VERSION:String:
	get:
		if not VERSION:
			VERSION = ProjectSettings.get_setting("application/config/version", "")
		return VERSION
const LOG_PREFIX:String = "[color=white][b]MAIN[/b]:: "

@export var splash_scene:PackedScene
@export var main_menu_scene:PackedScene: ## We don't have a main menu yet
	get:
		if not main_menu_scene:
			push_warning("Main.tscn is configured to launch Main Menu scene, but there isn't one configured. Reverting to Developer Main Menu scene.")
			return dev_main_menu_scene
		else:
			return main_menu_scene
			
@export var dev_main_menu_scene:PackedScene
@export var load_to_developer_menu:bool = true
@export var skip_splash:bool = false

@export var show_debug_scene_label:bool = true
@export var show_project_version_label:bool = true

#@export_group("Progression")
@export_file var levels: Array[String] ## In order

var instanced_root: Node
var current_packed_scene: PackedScene ## Set each time [method change_scene] is called.

@onready var debug_scene_label: RichTextLabel = %DebugSceneLabel
@onready var project_version_label: Label = %ProjectVersionLabel
@onready var options_panel: PanelContainer = %OptionsPanel

@onready var music_menu_loop: AudioStreamPlayer = $Music_MenuLoop
@onready var music_sherman: AudioStreamPlayer = $Music_Sherman

@onready var blip_neutral: AudioStreamPlayer = $Blip_Neutral

## Static instance, we should only have one Main in the scene tree at any time.
static var instance: Main:
	set(value):
		if instance != null:
			assert(
				not (is_instance_valid(instance) and not instance.is_queued_for_deletion()),
				"More than one instance of Main exists."
				)
		instance = value

## Static instance, we should only have one Level in the scene tree at any time.
## This method uses an assertion and should be used when you don't expect to handle
## a null value.
static func get_instance() -> Main:
	assert(instance)
	return instance
	
func _enter_tree() -> void:
	instance = self

## Called only once at program start.
func _ready() -> void:
	project_version_label.text = "v" + VERSION
	#if not debug build: ## TODO
		#debug_scene_label.hide()
	#el
	if show_debug_scene_label:
		debug_scene_label.show()
	else:
		debug_scene_label.hide()
	if show_project_version_label:
		project_version_label.show()
	else:
		project_version_label.hide()
		
	music_menu_loop.volume_linear = 0.0
	
	l("GLADIATOR OF THE GOLDEN HOUSE %s" % [VERSION])
	if not skip_splash:
		change_scene(splash_scene)
		assert(instanced_root is SplashMenu)
		await instanced_root.finished
	
	if load_to_developer_menu:
		change_scene(dev_main_menu_scene)
	else:
		change_scene(main_menu_scene)
		
static func reload_current_scene() -> void:
	change_scene(get_instance().current_packed_scene)
	
static func change_scene(packed_scene: PackedScene) -> void:
	get_instance()._change_scene(packed_scene)

static func change_scene_to_file(filepath: String) -> void:
	var scene: PackedScene = load(filepath)
	change_scene(scene)

## Prints the orphaned nodes to the console, if there are any.
func _check_print_orphans(msg: String) -> void:
	if not get_orphan_node_ids().is_empty():
		l(msg)
		print_orphan_nodes()

## If there is an active scene, unloads it, then instantiates [param packed_scene] and adds it as a child.
func _change_scene(packed_scene: PackedScene) -> void:
	_check_print_orphans("Orphaned nodes at scene exit:")
	assert(packed_scene)
	assert(packed_scene.can_instantiate())
	current_packed_scene = packed_scene
	
	if instanced_root:
		l("Unloading active scene...")
		# TODO maybe fade to black or something fancy to cover up the scene swap.
		if instanced_root is Level:
			instanced_root.is_complete = true ## HACK ?
		
		instanced_root.queue_free()
		await instanced_root.tree_exited
		instanced_root = null
		
	if get_tree().paused:
		get_tree().paused = false
	
	var scene_instance = packed_scene.instantiate()
	add_child(scene_instance)
	instanced_root = scene_instance
	
	var scene_name:String = (
		packed_scene.resource_path.get_base_dir() + "/"
		+ "  [b]"
		+ packed_scene.resource_path.get_file().trim_suffix(".tscn")
		)
	debug_scene_label.text = scene_name
	l("New active scene - loaded %s." % [packed_scene.resource_path])
	
	await get_tree().process_frame
	_check_print_orphans("Orphaned nodes after scene entrance:")
	
static func get_project_version() -> String:
	return ProjectSettings.get_setting("application/config/version", "")

static func l(to_print) -> void:
	print_rich("\n", LOG_PREFIX, to_print)
	

static func continue_level() -> void:
	play_level(PlayerData.this.current_level)

static func load_latest_level() -> void:
	play_level(PlayerData.this.current_level)
	
static func register_level_progressed() -> void:
	PlayerData.this.current_level += 1
	SaveLoad.save_game()
	
static func play_level(number: int) -> void:
	assert(number < instance.levels.size(), "Out of bounds!")
	change_scene_to_file(instance.levels[number])

static func show_options_panel() -> void:
	if not instance: return
	instance.options_panel.show()

static func go_to_main_menu() -> void:
	if not instance: return
	change_scene(instance.main_menu_scene)

func _on_return_to_menu_button_pressed() -> void:
	change_scene(main_menu_scene)

func _on_go_to_dev_menu_button_pressed() -> void:
	change_scene(dev_main_menu_scene)
	
	## HACK not really
	instance.play_music_menu_loop(false)
	instance.play_sherman(false)

static var music_fade: Tween
## True to play + fade in, false to fade out + stop
static func play_music_menu_loop(playing: bool) -> void:
	if not instance:
		return
	if music_fade:
		music_fade.kill()
	
	music_fade = instance.create_tween()
	music_fade.tween_property(
		instance.music_menu_loop,
		"volume_linear",
		1.0 if playing else 0.0,
		12.0 if playing else 4.0,
		).from(0.0 if playing else 1.0)
	
	if playing:
		instance.music_menu_loop.play()
	else:
		music_fade.tween_callback(instance.music_menu_loop.stop)

static var music_fade_2: Tween
static func play_sherman(playing: bool) -> void: ## true to play, false to fade out + stop
	if not instance:
		return
	if music_fade_2:
		music_fade_2.kill()
	
	music_fade_2 = instance.create_tween()
	music_fade_2.tween_property(
		instance.music_sherman,
		"volume_linear",
		1.0 if playing else 0.0,
		12.0 if playing else 4.0,
		).from(0.0 if playing else 1.0)
	
	if playing:
		instance.music_sherman.play()
	else:
		music_fade_2.tween_callback(instance.music_sherman.stop)

## Play a sfx blip.
static func sfx_blip() -> void:
	instance.blip_neutral.play()
