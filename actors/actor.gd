class_name Actor extends Node2D

signal queued_actions_finished(actor: Actor)
var emit_actions_finished_signal: bool = false

var current_tile_coords: Vector2i
var tile_map: TileMapLayer
var director: Director

var action_queue: ActionQueue

func setup(director_: Director, tilemap: TileMapLayer) -> void:
	self.director = director_
	self.tile_map = tilemap
	
	if action_queue:
		action_queue.free()
	action_queue = ActionQueue.new()
	action_queue.target = self
	action_queue.finished.connect(_on_action_queue_finished)
	
	
func get_action_queue() -> ActionQueue: return action_queue
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
	action_queue.run_action(action)
	
func _on_action_queue_finished() -> void:
	if emit_actions_finished_signal:
		queued_actions_finished.emit(self)


func move_to_tile(coords: Vector2i, map: TileMapLayer = tile_map) -> void:
	if not tile_map: return
	
	current_tile_coords = coords
	var move_tween := create_tween()
	move_tween.set_ease(Tween.EASE_OUT)
	move_tween.tween_property(self, ^"global_position", get_global_position_at(map, coords), 1.0)

static func get_global_position_at(map: TileMapLayer, coords: Vector2i) -> Vector2:
	return map.to_global(map.map_to_local(coords))
	
