extends AIDirector

const copy_actions: bool = true

@export var to_spawn: Array[PackedScene]

@onready var enemies_to_spawn: int = to_spawn.size()

var _enemies_spawned: int = 0

func _ready() -> void:
	await get_tree().process_frame
	Level.get_player_main_character().moved.connect(on_player_moved)

func on_player_moved(old_location: Vector2i, new_location: Vector2i) -> void:
	p("Player moved! %s old, %s new" % [old_location, new_location])
	if old_location != new_location:
		spawn_one_at(old_location)

func spawn_one_at(coords: Vector2i) -> void:
	if not to_spawn: return
	if to_spawn.is_empty(): return
	if Level.get_actor_at(coords): return
	
	p("Special level spawning actor behind player...")
	
	var spawn: Actor = to_spawn.pop_front().instantiate()
	Juice.fade_in(spawn, Juice.SLOW)
	add_child(spawn)
	
	## set up action
	add_actor_for_next_turn(spawn)
	spawn.relocate_root_to_coords(coords)
	if copy_actions and spawn is AIActor:
		spawn.replace_usable_actions(Level.get_player_main_character().get_usable_actions())

func has_actors() -> bool: ## Level.gd check objective win condition
	if _enemies_spawned < enemies_to_spawn:
		return true
	elif actors.is_empty():
		return false
	else:
		return true
