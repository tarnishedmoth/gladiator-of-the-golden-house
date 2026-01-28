class_name Main extends Node

## Perform any initialization steps,
## Skip to the Developer Main Menu, or
## Load the splash,
## then load the main menu.

static var VERSION:String:
	get:
		if not VERSION:
			VERSION = ProjectSettings.get_setting("application/config/version", "")
		return VERSION
const LOG_PREFIX:String = "MAIN:: "

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

var instanced_root: Node

@onready var debug_scene_label: RichTextLabel = %DebugSceneLabel
@onready var project_version_label: Label = %ProjectVersionLabel

## Called only once at program start.
func _ready() -> void:
	project_version_label.text = "v" + VERSION
	#if not debug build: ## TODO FIXME
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
	
	l("GLADIATOR OF THE GOLDEN HOUSE %s" % [VERSION])
	if not skip_splash:
		change_scene(splash_scene)
		assert(instanced_root is SplashMenu)
		await instanced_root.finished
		
	if load_to_developer_menu:
		change_scene(dev_main_menu_scene)
	else:
		change_scene(main_menu_scene)
	
## If there is an active scene, unloads it, then instantiates [param packed_scene] and adds it as a child.
func change_scene(packed_scene: PackedScene) -> void:
	assert(packed_scene)
	assert(packed_scene.can_instantiate())
	
	if instanced_root:
		l("Unloading active scene.")
		# TODO maybe fade to black or something fancy to cover up the scene swap.
		instanced_root.queue_free()
		await instanced_root.tree_exited
		instanced_root = null
	
	var instance = packed_scene.instantiate()
	add_child(instance)
	instanced_root = instance
	
	var scene_name:String = (
		packed_scene.resource_path.get_base_dir() + "/"
		+ "  [b]"
		+ packed_scene.resource_path.get_file().trim_suffix(".tscn")
		)
	debug_scene_label.text = scene_name
	l("New active scene - loaded %s." % [packed_scene.resource_path])
	
static func get_project_version() -> String:
	return ProjectSettings.get_setting("application/config/version", "")

static func l(to_print) -> void:
	print(LOG_PREFIX, to_print)


func _on_return_to_menu_button_pressed() -> void:
	if load_to_developer_menu:
		change_scene(dev_main_menu_scene)
	else:
		change_scene(main_menu_scene)
