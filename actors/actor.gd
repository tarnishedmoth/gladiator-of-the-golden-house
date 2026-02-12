class_name Actor extends Node2D

const SHOW_DEBUG_FACING_INDICATOR: bool = true
const DEBUG_FACING_INDICATOR_SCENE = preload("uid://b3kl75n4nwdge")
var debug_facing_indicator: Node2D ## instantiated at runtime


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


#region STATIC METHODS

static func get_global_position_at(map: TileMapLayer, coords: Vector2i) -> Vector2:
	return map.to_global(map.map_to_local(coords))
	
#endregion


func setup(director_: Director, tilemap: TileMapLayer) -> void:
	self.director = director_
	self.tile_map = tilemap

	_snap_to_nearest_tile()

	if action_queue:
		action_queue.free()
	action_queue = ActionQueue.new()
	action_queue.setup(self)
	
	health = starting_health

	################################################## DEBUG ONLY
	# take random damage to test the health bar
	@warning_ignore("narrowing_conversion")
	take_damage(randi_range(0, starting_health*0.9))
	################################################## DEBUG ONLY

#region ACTIONS

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

#endregion

#region MOVEMENT

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
	
	if SHOW_DEBUG_FACING_INDICATOR && self.is_inside_tree():
		show_debug_facing_indicator(true)
	
func get_facing_values() -> DirectionPattern:
	return Facing.rotate(face_direction_pattern, facing)
	
func show_debug_facing_indicator(show_: bool = true) -> void:
	if not show_:
		if debug_facing_indicator:
			debug_facing_indicator.free()
	else:
		if not debug_facing_indicator:
			debug_facing_indicator = DEBUG_FACING_INDICATOR_SCENE.instantiate()
			add_child(debug_facing_indicator)
		
		## Set rotation
		var degrees: int = 60 * facing
		debug_facing_indicator.rotation_degrees = degrees
		print("Facing %s and rotated to %d degrees." % [facing, degrees])
		
#endregion

#region HEALTH

func update_healthbar() -> void:
	## TODO save healthbar as scene and instantiate at runtime
	if is_instance_valid($health/bar):
		$health/bar.scale.x = float(health)/float(starting_health)
	if is_instance_valid($health/txt):
		$health/txt.text = str(health)
	
func take_damage(damage: int) -> void:
	health -= damage
	health = maxi(0, health)
	update_healthbar()

#endregion
