class_name Actor extends Node2D

@export var debug: bool = true
func p(args):
	print_rich("[bgcolor=grey][color=black]", "Actor %s : " % name, args)

const SHOW_DEBUG_FACING_INDICATOR: bool = true
const DEBUG_FACING_INDICATOR_SCENE = preload("uid://b3kl75n4nwdge")
var debug_facing_indicator: Node2D ## instantiated at runtime

const TARGET_INDICATOR = preload("uid://bw78572gtph87")
var target_scene: PackedScene = TARGET_INDICATOR

signal animation_finished
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

@export var facing: Facing.Cardinal = Facing.Cardinal.NORTH

var health: int
@export var starting_health: int

var energy: int
@export var starting_energy: int

@export_category("Status Effects:")
@export var status_effects: Array[Status]

#region STATIC METHODS

static func get_global_position_at(map: TileMapLayer, coords: Vector2i) -> Vector2:
	return map.to_global(map.map_to_local(coords))
	
#endregion


func setup(director_: Director, tilemap: TileMapLayer) -> void:
	self.director = director_
	self.tile_map = tilemap
	
	tree_exited.connect(self.director.actors.erase.bind(self))
	
	snap_to_nearest_tile()

	if action_queue:
		action_queue.free()
	action_queue = ActionQueue.new()
	action_queue.setup(self)
	
	health = starting_health
	energy = starting_energy
	
	update_healthbar()

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

func snap_to_nearest_tile() -> void:
	var tile_coords: Vector2i = tile_map.local_to_map(tile_map.to_local(global_position))
	assert(TileInteractor.cell_exists(tile_coords, tile_map))
	global_position = get_global_position_at(tile_map, tile_coords)
	
	current_tile_coords = tile_coords

func move_to_tile(coords: Vector2i, map: TileMapLayer = tile_map) -> void:
	if not tile_map: return

	## Prevent moving onto a tile occupied by another actor
	var occupant: Actor = Level.get_actor_at(coords)
	if occupant != null and occupant != self:
		push_warning("Actor %s tried to move to %s but it is occupied by %s. Staying in place." % [name, coords, occupant.name])
		animation_finished.emit()
		return

	current_tile_coords = coords
	var move_tween := create_tween()
	move_tween.set_trans(Tween.TRANS_QUAD)

	var duration_of_movement: float = 0.75 ## TODO should probably depend on distance covered
	move_tween.tween_property(self, ^"global_position", get_global_position_at(map, coords), duration_of_movement)
	move_tween.tween_callback(animation_finished.emit)

## Sets [member facing]. North is the default value.
func set_facing(cardinal_direction: Facing.Cardinal) -> void:
	facing = cardinal_direction
	
	if SHOW_DEBUG_FACING_INDICATOR && self.is_inside_tree():
		show_debug_facing_indicator(true)
	
## Returns [member facing]. North is the default value.
func get_facing() -> Facing.Cardinal:
	return facing
	
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
		
		if debug:
			p("Facing %s and rotated to %d degrees." % [facing, degrees])
		
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
	
	if debug:
		p("%s incoming damage" % [damage_result])
	
	##loop through status effects to recalculate damage_result
	for effect in status_effects:
		damage_result = effect.on_take_damage(damage_result)
		
	health -= damage_result
	health = maxi(0, health)
	update_healthbar()
	
	if health <= 0:
		die()
		
func die() -> void:
	## TODO
	Juice.fade_out(self).tween_callback(queue_free)

#endregion

#region Energy

func add_energy(amount:int):
	energy += amount
	if debug:
		p("%s energy has been added, total energy: %s" % [amount,energy])

func remove_energy(amount:int):
	energy -= amount
	if debug:
		p("%s energy has been removed, total energy: %s" % [amount,energy])

func reset_energy() -> void:
	energy = starting_energy

#endregion

#region Status Effects

func add_status(status: Status, do_duplicate: bool = true) -> void:
	if status in status_effects:
		var _status = status_effects.get(status_effects.find(status))
		_status.add_points(status.effect_points)
		if debug:
			p("Added %d points to status %s." % [status.effect_points, _status.ui_name])
	else:
		var new_status: Status
		if do_duplicate:
			new_status = status.duplicate()
		else:
			new_status = status
			
		new_status.set_actor(self) #setting self to take status effect
		status_effects.append(new_status)
		if debug:
			p("Added new status %s." % new_status.ui_name)
	
func remove_status(status: Status) -> void:
	status_effects.erase(status)
	
func process_on_turn_start_status_effects() -> void:
	if debug and not status_effects.is_empty():
		p("Started turn with status effects: %s" % status_effects)
	for status in status_effects:
		status.on_turn_start()

#endregion

#region Highlighting & Planning

func get_action_target_cells(action: Action) -> Array[Vector2i]:
	if "pattern" in action:
		return get_translated_pattern(action.pattern)
	else:
		return get_translated_pattern(Action.NO_PATTERN)

func get_translated_pattern(pattern: Array[Vector2i]) -> Array[Vector2i]:
	return Facing.get_target_cells(current_tile_coords, facing, pattern)

#endregion
