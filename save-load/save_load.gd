class_name SaveLoad

## Credit: following along with TheDuriel's examples given
## https://theduriel.github.io/Godot/Saving-and-Loading

## We're calling saving "capture" and loading "apply".
## There is a simple single backup system.

## Top down saving.
## Save file contents are two variables:
## 1. Metadata (identifiers)
## 2. Dictionary (bulk save data)
## When loading a save file in entirety, a LoadedSave object is returned.
## When loading only the metadata, a Metadata object is returned.

## To incorporate something into the save system:
## 1 & 2. Implement these methods on any object.
#func capture_save_data() -> Dictionary:
#func apply_save_data(save: SaveLoad.LoadedSave) -> void:
## 3. SaveLoad.subscribe()
## 4. SaveLoad.unsubscribe() when exiting.

static func p(args): print_rich("[color=green]SaveLoad: ", args)

const SAVE_DIRECTORY: String = "user://saves/"
const SAVE_EXTENSION: String = ".save"
const BACKUP_EXTENSION: String = ".old"

static var current_save_slot: int = 0

class LoadedSave:
	var meta: Metadata
	var data: Dictionary


class Metadata:
	var system_time: float
	var display_summary: String

	func to_dict() -> Dictionary:
		var meta_dict: Dictionary = {}
		meta_dict.system_time = system_time
		meta_dict.display_summary = display_summary
		return meta_dict

	static func from_dict(dict: Dictionary) -> Metadata:
		var m: Metadata = Metadata.new()
		m.system_time = dict.system_time
		m.display_summary = dict.display_summary
		return m


static func _capture_metadata() -> Metadata:
	var meta: Metadata = Metadata.new()
	meta.system_time = Time.get_unix_time_from_system()
	
	var tool = Playtime.new()
	tool.set_seconds(PlayerData.this.combat_playtime)
	var string_time: String = tool.get_string_time()
	var class_display_name: String = PlayerData.STARTING_CLASSES.find_key(PlayerData.this.choice_starting_class)
	class_display_name = class_display_name.capitalize() ## dang this method is cool
	
	meta.display_summary = "%s (%s) - %s: %3d" % \
	[PlayerData.this.choice_name, class_display_name, string_time,
	(float(PlayerData.this.current_level) / Main.get_instance().levels.size()) * 100.0] + "%"
	
	return meta


static func check_and_create_directory(dir_path: String) -> void:
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)

## Returns a list of full file paths.
static func get_save_slots() -> PackedStringArray:
	check_and_create_directory(SAVE_DIRECTORY)
	
	var dir: DirAccess = DirAccess.open(SAVE_DIRECTORY)
	if not dir:
		push_error("No directory found at path: %s" % SAVE_DIRECTORY)
		return []
	else:
		var save_files := PackedStringArray()
		
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				## Found a file
				if file_name.ends_with(SAVE_EXTENSION):
					
					save_files.append(SAVE_DIRECTORY + "/" + file_name)
					
			file_name = dir.get_next()
		return save_files
	
#endregion
#region SAVE & LOAD
static var last_save_path: String = GameSettings.get_value(
	GameSettings.SECTION.SAVES,
	"last_save_path",
	get_filepath_for_slot(0) ## default save slot
	)
static func save_game(slot: int = current_save_slot) -> void:
	p("Saving game in save slot %d..." % slot)
	_capture_save_to_disk(get_filepath_for_slot(slot))
	
	GameSettings.save_config()
	
static func reload_last_save() -> void:
	load_game(last_save_path)
	
static func load_current_save_slot() -> void:
	load_game(get_filepath_for_slot(current_save_slot))
	
static func load_game(file_path: String) -> void:
	last_save_path = file_path
	
	var save: LoadedSave = _load_save_from_disk(file_path)
	
	_apply_save_data_to_all(save)
	
static func get_filepath_for_slot(slot:int = 0) -> String:
	return SAVE_DIRECTORY + "/slot_" + str(slot) + SAVE_EXTENSION

#region FILE ACCESS

static func backup_file(file_path: String) -> void:
	if not FileAccess.file_exists(file_path):
		return
	else:
		var backup_path: String = file_path + BACKUP_EXTENSION
		if FileAccess.file_exists(backup_path):
			OS.move_to_trash(ProjectSettings.globalize_path(backup_path))
			p("Overwriting save slot backup.")
		else:
			p("Backing up save slot.")
		DirAccess.rename_absolute(file_path, backup_path)

static func _capture_save_to_disk(file_path: String) -> void:
	check_and_create_directory(file_path.get_base_dir())
	
	if not DirAccess.dir_exists_absolute(file_path.get_base_dir()):
		push_error("Failed to access directory while saving.")
		return
	
	last_save_path = file_path
	
	backup_file(file_path)
	
	var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
	
	## Store meta
	var meta: Metadata = _capture_metadata()
	var meta_dict: Dictionary = meta.to_dict()
	file.store_var(meta_dict)
	
	## Store data
	var player_data: Dictionary = PlayerData.capture_save_data()
	if not player_data.is_empty():
		file.store_var(player_data)
	
	file.close()
	
	p("saved at %s" % file_path)
	
	
## Returns null if the file does not exist.
static func load_metadata_from_disk(file_path: String) -> Metadata:
	if FileAccess.file_exists(file_path):
		var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
		return _load_metadata_from_file(file)
	else:
		return null

static func _load_metadata_from_file(file: FileAccess, and_close: bool = true) -> Metadata:
	var meta_dict: Dictionary = file.get_var()

	if and_close:
		file.close()

	return Metadata.from_dict(meta_dict)

static func _load_save_from_disk(file_path: String) -> LoadedSave:
	var save: LoadedSave = LoadedSave.new()
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	
	save.meta = _load_metadata_from_file(file, false)
	save.data = file.get_var()
	file.close()
	
	p("loaded from %s" % file_path)

	return save

#endregion
#region APPLY

static func _apply_save_data_to_all(save: LoadedSave) -> void:
	p("Applying loaded game data...")
	
	## Set PlayerData
	PlayerData.apply_save_data(save)
	
	## Propogate the call to all subscribers
	for object in subscribers:
		object.apply_save_data(save)
		p("Applied to %s" % object)

#endregion
#region SUBSCRIPTION

static var subscribers: Array[Object] ## Each expected to have two methods: one for capture and one for apply.

static func subscribe(object: Object) -> void:
	if not object in subscribers:
		subscribers.append(object)
	else:
		## Might be desired behavior, HACK
		## Erase old entry and move to the end.
		subscribers.erase(object)
		subscribers.append(object)
		
static func unsubscribe(object: Object) -> void:
	subscribers.erase(object)

#endregion
