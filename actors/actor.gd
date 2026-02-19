class_name Actor extends Node2D

const SHOW_DEBUG_FACING_INDICATOR: bool = true
const DEBUG_FACING_INDICATOR_SCENE = preload("uid://b3kl75n4nwdge")
const TARGET_INDICATOR = preload("uid://bw78572gtph87")
var target_scene: PackedScene = TARGET_INDICATOR
var debug_facing_indicator: Node2D ## instantiated at runtime

signal queued_actions_finished(actor: Actor)
var emit_actions_finished_signal: bool = false

var current_tile_coords: Vector2i
var tile_map: TileMapLayer
var director: Director

var action_queue: ActionQueue
func get_action_queue() -> ActionQueue: return action_queue

@export var ui_name: String ## Shown in Hover Panel
@export var ui_subtitle: String ## (Optional) Shown in hover panel
@export_multiline() var ui_description: String ## (Optional) Shown in Hover Panel

var facing: Facing.Cardinal
@export var face_direction_pattern: DirectionPattern = preload("uid://d1amb27satk2b")

var health: int
@export var starting_health: int

@export_category("Attacks:")
@export var attack_one: ActionAttack

@export_category("Status Effects:")
@export var _status_effects: Array[Status]
@export var status_effect: Status # Debug this will be removed once we have status effect actions

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
	#defense status effect test
	self.add_status(status_effect)
	
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
	global_position = get_global_position_at(tile_map, tile_coords)
	current_tile_coords = tile_coords

func move_to_tile(coords: Vector2i, map: TileMapLayer = tile_map) -> void:
	if not tile_map: return
	
	current_tile_coords = coords
	var move_tween := create_tween()
	move_tween.set_trans(Tween.TRANS_QUAD)
	
	var duration_of_movement: float = 0.75 ## TODO should probably depend on distance covered
	move_tween.tween_property(self, ^"global_position", get_global_position_at(map, coords), duration_of_movement)
	
func set_facing(cardinal_direction: Facing.Cardinal) -> void:
	facing = cardinal_direction
	
	if SHOW_DEBUG_FACING_INDICATOR && self.is_inside_tree():
		show_debug_facing_indicator(true)
	
func get_facing_values() -> DirectionPattern: # dont think we need this anymore
	return
	
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
	var bar = get_node_or_null("health/bar")
	if is_instance_valid(bar):
		bar.scale.x = float(health)/float(starting_health)
	var txt = get_node_or_null("health/txt")
	if is_instance_valid(txt):
		txt.text = str(health)
	
func take_damage(damage: int) -> void:
	
	var damage_result: int = damage
	
	print("%s incoming damage" % [damage_result])
	
	##loop through status effects to recalculate damage_result
	for effect in _status_effects:
		damage_result = effect.on_take_damage(damage_result)
		
	health -= damage_result
	health = maxi(0, health)
	update_healthbar()

#endregion

#region Status Effects

func add_status(status: Status) -> void:
	var new_status:Status = status.duplicate()
	new_status.set_actor(self) #setting self to take status effect
	
	var index: int =_status_effects.find(new_status)
	_status_effects.remove_at(index) #Removes old status effect
	_status_effects.append(new_status) 
	
func remove_status(status: Status) -> void:
	_status_effects.erase(status)
	
func process_on_turn_start_status_effects() -> void:
	for status in _status_effects:
		status.on_turn_start()

#endregion
