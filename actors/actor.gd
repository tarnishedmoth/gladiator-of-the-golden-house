class_name Actor extends Node2D

signal queued_actions_finished(actor: Actor)
var emit_actions_finished_signal: bool = false

var current_tile_coords: Vector2i
var tile_map: TileMapLayer
var director: Director

var action_queue: ActionQueue
func get_action_queue() -> ActionQueue: return action_queue

var facing: Facing.Cardinal
@export var face_direction_pattern: DirectionPattern = preload("uid://d1amb27satk2b")

var health: int
@export var starting_health: int

func setup(director_: Director, tilemap: TileMapLayer) -> void:
	self.director = director_
	self.tile_map = tilemap

	_snap_to_nearest_tile()

	if action_queue:
		action_queue.free()
	action_queue = ActionQueue.new()
	action_queue.setup(self)
	
	health = starting_health


func run_queued_actions() -> void: ## Emits a signal when done.
	emit_actions_finished_signal = true
	action_queue.run_queue()

func queue_action(action: Action, and_run_queue: bool = false) -> void:
	action_queue.queue.append(action)
	if and_run_queue:
		run_queued_actions()
		
func append_actions_to_queue(array: Array[Action]) -> void:
	action_queue.queue.append_array(array)

func run_action(action: Action) -> void: ## Immediately runs one action (and any chained actions).
	if action_queue.running_queue:
		push_warning("Action queue is apparently running the queue / Check for bad state?")
	action_queue.run_action(action)
	
func _on_action_queue_finished() -> void:
	if emit_actions_finished_signal:
		queued_actions_finished.emit(self)


func _snap_to_nearest_tile() -> void:
	var tile_coords: Vector2i = tile_map.local_to_map(tile_map.to_local(global_position))
	assert(TileInteractor.cell_exists(tile_coords, tile_map))
	current_tile_coords = tile_coords
	global_position = get_global_position_at(tile_map, tile_coords)

func move_to_tile(coords: Vector2i, map: TileMapLayer = tile_map) -> void:
	if not tile_map: return
	
	current_tile_coords = coords
	var move_tween := create_tween()
	move_tween.set_ease(Tween.EASE_OUT)
	move_tween.tween_property(self, ^"global_position", get_global_position_at(map, coords), 1.0)
	
func set_facing(cardinal_direction: Facing.Cardinal) -> void:
	facing = cardinal_direction
	
func get_facing_values() -> DirectionPattern:
	return Facing.rotate(face_direction_pattern, facing)

static func get_global_position_at(map: TileMapLayer, coords: Vector2i) -> Vector2:
	return map.to_global(map.map_to_local(coords))
	
func take_damage(damage: int) -> void:
	health -= damage
	health = maxi(0, health)
