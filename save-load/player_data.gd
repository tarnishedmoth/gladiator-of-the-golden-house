class_name PlayerData

## Holds everything relevant to a playthrough.

static func p(args): ## Print method
	print_rich("[bgcolor=cyan][color=purple]", "PlayerData: ", args)

#region Variables & Getters

## You can hover over these UID strings in the editor IDE to quickly access
## the actual source file.
## These are PlayerDirector scenes with the configured set of actions.
const STARTING_CLASSES: Dictionary[StringName, String] = {
	SHORT_SWORD = "uid://bet8eq50pbkqf",
	GREATSWORD = "uid://c5tt5o8dkeve3",
	FLOWING_FLAIL = "uid://jo8005ytejoy",
}

## These are scenes with the art assets specifically.
const CHARACTER_SCENES: Dictionary[StringName, String] = {
	NOBODY = "uid://dkxist2lihrf0",
	CHARLES = "uid://l5cyxitgqmvp",
	EDRIS = "uid://xpbxvcrymw24",
	XODIAC = "uid://dupb85srefjlo",
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

static func get_starting_class_description(starting_class_file_uid: String) -> String:
	match starting_class_file_uid:
		STARTING_CLASSES.SHORT_SWORD:
			return \
			"A balanced, enduring build.
			Close quarters combat is your speciality, & persistence your ally."
		
		STARTING_CLASSES.GREATSWORD:
			return \
			"Not entirely bereft of defensive ability, your weapon affords greater reach, and the strength to knockback most foes.
			Stance changes allow for switching between using both hands to properly wield the weapon, or equipping a meagre shield..."
		
		STARTING_CLASSES.FLOWING_FLAIL:
			return \
			"This weapon's momentum compounds with each chained attack, delivering devastating final blows.
			Excels at mid-range encounters. The alternate stance affords more mobility."
	
	return ""

var combat_playtime: float ## See [Playtime] class for conversion

var current_level: int = 0
func get_current_level() -> int: return current_level

var current_loss_streak: int = 0

var persistent_actors: Dictionary[StringName, PersistentActorData]

## CRITICAL Bump SAVE_VERSION when any of these change incompatibly:
## - PersistentActorData.to_dict keys (and not handled via d.get default)
## - Status.to_dict keys
## - Action.to_dict keys
## - Top-level keys in capture_save_data
## Bump NOT required for additive fields read via `d.get(key, default)`.
const SAVE_VERSION: int = 3

static var this: PlayerData ## Static object

#endregion

## [param chosen_name] can be anything, [param chosen_starting_class] [param chosen_character_art] must be UID as a string.
## See [member STARTING_CLASSES] and [member CHARACTER_SCENES]
static func new_playthrough(chosen_name: String, chosen_starting_class: String, chosen_character_scene: String) -> void:
	if this:
		p("Overwriting data!")
	p("%s starting a new playthrough as %s." % [chosen_name, STARTING_CLASSES.find_key(chosen_starting_class)])
	
	this = PlayerData.new()
	this.choice_name = chosen_name
	this.choice_starting_class = chosen_starting_class
	this.choice_character_scene = chosen_character_scene
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
	
static func wipe_actor_data() -> void:
	if not this:
		return
	else:
		this.persistent_actors.clear()


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
		"choice_character_scene": this.choice_character_scene,
		"combat_playtime": this.combat_playtime,
		"current_level": this.current_level,
		"current_loss_streak": this.current_loss_streak,
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
	this.choice_character_scene = data.get("choice_character_scene", CHARACTER_SCENES.values().front())
	this.combat_playtime = data.get("combat_playtime", 0.0)
	this.current_level = data.get("current_level", 0)
	this.current_loss_streak = data.get("current_loss_streak", 0)
	
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


func on_game_completed() -> void:
	GameSettings.set_value(GameSettings.SECTION.COMPLETIONS, "game_completed", true)
	
	var starting_class_name: String = String(STARTING_CLASSES.find_key(this.choice_starting_class)).capitalize()
	var times_beaten: int = GameSettings.get_value(GameSettings.SECTION.COMPLETIONS, starting_class_name, 0) + 1
	GameSettings.set_value(GameSettings.SECTION.COMPLETIONS, starting_class_name, times_beaten)
