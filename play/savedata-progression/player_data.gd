class_name PlayerData

## Holds everything relevant to a playthrough.

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

var persistent_actors: Dictionary[StringName, Actor.PersistentActorData]

static var this: PlayerData

static func new_playthrough(chosen_name: String, chosen_starting_class: String) -> void:
	if this:
		p("Overwriting data!")
	p("%s starting a new playthrough as %s." % [chosen_name, STARTING_CLASSES.find_key("uid://bet8eq50pbkqf")])
	
	this = PlayerData.new()
	this.choice_name = chosen_name
	this.choice_starting_class = chosen_starting_class

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
