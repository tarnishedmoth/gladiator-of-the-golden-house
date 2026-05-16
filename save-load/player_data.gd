class_name PlayerData

## Holds everything relevant to a playthrough.

static func p(args): ## Print method
	print_rich("[bgcolor=cyan][color=purple]", "PlayerData: ", args)

#region Variables & Getters

## You can hover over these UID strings in the editor IDE to quickly access
## the actual source file.
## These are PlayerDirector scenes with the configured set of actions.
const STARTING_CLASSES: Dictionary[StringName, String] = {
	CLASSIC = "uid://bet8eq50pbkqf",
	GREATSWORD = "uid://c5tt5o8dkeve3",
}

var choice_name: String ## Display name used for save metadata shown to user

var choice_starting_class: String ## File UID
func get_chosen_starting_class_scene() -> PackedScene: ## Should be of type [Player] when instantiated
	return load(choice_starting_class)

var choice_character_scene: String ## File UID
func get_character_scene() -> PackedScene:
	#if not choice_character_scene: return null
	assert(choice_character_scene)
	var scene: PackedScene = ResourceLoader.load(choice_character_scene, "PackedScene", ResourceLoader.CACHE_MODE_REUSE)
	return scene

var combat_playtime: float ## See [Playtime] class for conversion

var current_level: int = 0
func get_current_level() -> int: return current_level

var persistent_actors: Dictionary[StringName, PersistentActorData]

## CRITICAL Bump SAVE_VERSION when any of these change incompatibly:
## - PersistentActorData.to_dict keys (and not handled via d.get default)
## - Status.to_dict keys
## - Action.to_dict keys
## - Top-level keys in capture_save_data
## Bump NOT required for additive fields read via `d.get(key, default)`.
const SAVE_VERSION: int = 1

static func new_playthrough(chosen_name: String, chosen_starting_class: String) -> void:
	if this:
		p("Overwriting data!")
	p("%s starting a new playthrough as %s." % [chosen_name, STARTING_CLASSES.find_key(chosen_starting_class)])
	
	this = PlayerData.new()
	this.choice_name = chosen_name
	this.choice_starting_class = chosen_starting_class
	this.combat_playtime = 0.0
	

static func get_actor_data(actor_key: StringName) -> PersistentActorData:
	if not this:
		push_warning("No playthrough active.")
		p("No playthrough active.")
		return
	elif not actor_key in this.persistent_actors:
		return
	else:
		return this.persistent_actors[actor_key]
		
static func set_actor_data(actor_key: StringName, data: PersistentActorData):
	if not this:
		push_warning("No playthrough active.")
		p("No playthrough active.")
		return
	elif actor_key in this.persistent_actors:
		p("Overwriting actor %s persistent data." % str(actor_key))
	else:
		p("Registering actor %s persistent data." % str(actor_key))
	this.persistent_actors[actor_key] = data


#region SAVE/LOAD
static func capture_save_data() -> Dictionary:
	if not this:
		return {}
	var actors_dict: Dictionary = {}
	for actor_key in this.persistent_actors.keys():
		actors_dict[actor_key] = this.persistent_actors[actor_key].to_dict()
	return {
		"save_version": SAVE_VERSION,
		"choice_name": this.choice_name,
		"choice_starting_class": this.choice_starting_class,
		"combat_playtime": this.combat_playtime,
		"current_level": this.current_level,
		"persistent_actors": actors_dict,
	}

static func apply_save_data(save: SaveLoad.LoadedSave) -> void:
	if not save or not save.data:
		push_error("PlayerData.apply_save_data: null save data.")
		return
	var data: Dictionary = save.data
	var version: int = data.get("save_version", 0)
	if version != SAVE_VERSION:
		push_error("Save file is in incompatible format (version=%d, expected=%d). Delete %s to continue."
			% [version, SAVE_VERSION, ProjectSettings.globalize_path(SaveLoad.SAVE_DIRECTORY)])
		return

	this = PlayerData.new()
	this.choice_name = data.get("choice_name", "")
	this.choice_starting_class = data.get("choice_starting_class", "")
	this.combat_playtime = data.get("combat_playtime", 0.0)
	this.current_level = data.get("current_level", 0)

	this.persistent_actors = {}
	var actors_dict: Dictionary = data.get("persistent_actors", {})
	for actor_key in actors_dict.keys():
		var raw = actors_dict[actor_key]
		if not raw is Dictionary:
			push_error("Save slot has malformed persistent_actors entry for %s; skipping." % actor_key)
			continue
		## Coerce key to StringName so the typed Dictionary[StringName, ...] accepts it.
		this.persistent_actors[StringName(actor_key)] = PersistentActorData.from_dict(raw)
	p("Applied save data.")
