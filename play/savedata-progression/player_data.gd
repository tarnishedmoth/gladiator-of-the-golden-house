class_name PlayerData

## Holds everything relevant to a playthrough.
static var this: PlayerData

static func p(args):
	print_rich("[bgcolor=cyan][color=purple]", "PlayerData: ", args)

## You can hover over these UID strings in the editor IDE to quickly access
## the actual source file.
const STARTING_CLASSES: Dictionary = {
	A = "uid://bet8eq50pbkqf",
}

var choice_name: String
var choice_starting_class: String

var current_level: int = 0
func get_current_level() -> int: return current_level

var persistent_actors: Dictionary[StringName, Actor.PersistentActorData]

static func new_playthrough(chosen_name: String, chosen_starting_class: String) -> void:
	if this:
		p("Overwriting data!")
	p("%s starting a new playthrough as %s." % [chosen_name, STARTING_CLASSES.find_key(chosen_starting_class)])
	
	this = PlayerData.new()
	this.choice_name = chosen_name
	this.choice_starting_class = chosen_starting_class
	
func get_chosen_starting_class_scene() -> PackedScene: ## Should be of type [Player] when instantiated
	return load(choice_starting_class)

static func get_actor_data(actor_key: StringName) -> Actor.PersistentActorData:
	if not this:
		push_warning("No playthrough active.")
		p("No playthrough active.")
		return
	elif not actor_key in this.persistent_actors:
		return
	else:
		return this.persistent_actors[actor_key]
		
static func set_actor_data(actor_key: StringName, data: Actor.PersistentActorData):
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
	else:
		var _persistent_actors: Dictionary = {}
		for actor in this.persistent_actors.keys():
			_persistent_actors[actor] = JSON.stringify(this.persistent_actors[actor])
		
		var data = {
			"choice_name" = this.choice_name,
			"choice_starting_class" = this.choice_starting_class,
			"current_level" = this.current_level,
			"persistent_actors" = _persistent_actors,
		}
		return data
	
static func apply_save_data(save: SaveLoad.LoadedSave) -> void:
	var data = save.data
	assert(data)
	
	this = PlayerData.new()
	
	this.choice_name = data["choice_name"]
	this.choice_starting_class = data["choice_starting_class"]
	this.current_level = data["current_level"]
	
	this.persistent_actors = {}
	var _persistent_actors: Dictionary = data["persistent_actors"]
	for actor in _persistent_actors.keys():
		this.persistent_actors[actor] = JSON.to_native(JSON.parse_string(_persistent_actors[actor]), true)
	
	p("Applied save data.")
