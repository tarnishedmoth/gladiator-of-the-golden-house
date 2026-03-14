class_name Actor extends Node2D

## A thing that does things when things tell it it can, and also what things to do.
## 
## This guy can do things by using an [Action].
## Actions are responsible for making an Actor actually *do* anything, often by calling
## methods in [Actor].
## We use a state machine called an [ActionQueue].
## Generally, actors don't do anything until a [Director] tells them that they can. See [method on_turn_start].
## Directors don't micro-manage Actors, though. See [AIActor] for more of that.

@export var debug: bool = true
func p(args):
	print_rich("[bgcolor=grey][color=black]", "Actor %s : " % name, args)


## Level related functionality
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


## Managers (objects that do things)
var action_queue: ActionQueue
func get_action_queue() -> ActionQueue: ## Use when you dont expect to handle null.
	assert(action_queue)
	return action_queue

var status_manager: StatusManager
func get_status_manager() -> StatusManager: ## Use when you dont expect to handle null.
	assert(status_manager)
	return status_manager

var sfx: ActorSfxHandler
func get_sfx_handler() -> ActorSfxHandler:
	assert(sfx)
	return sfx


## Save / Load
class PersistentActorData extends Resource:
	var max_health: int
	var current_health: int
	var starting_energy: int
	var starting_status_effects: Array[Status]
	
	var ui_name: String
	var ui_subtitle: String
	var ui_description: String
	
	func set_stats_from_actor(actor: Actor, include_ui: bool = false) -> void:
		max_health = actor.starting_health
		current_health = actor.health
		starting_energy = actor.starting_energy
		
		if include_ui:
			ui_name = actor.ui_name
			ui_subtitle = actor.ui_subtitle
			ui_description = actor.ui_description
			
	func persist_status(status: Status) -> void:
		starting_status_effects.append(status)

var persistent_actor_data: PersistentActorData
@export_group("Persistent Data", "persistent_")
@export var persistent_data_key: StringName ## Only for story characters (player, etc)

func set_stats_from_data(data: PersistentActorData = persistent_actor_data) -> void:
	assert(data)
	health = data.current_health
	starting_energy = data.starting_energy

func push_persistent_data() -> void:
	if persistent_data_key:
		assert(persistent_actor_data)
		PlayerData.set_actor_data(persistent_data_key, persistent_actor_data)


## Gameplay
@export var ui_name: String ## Shown in Hover Panel
@export var ui_subtitle: String ## (Optional) Shown in hover panel
@export_multiline() var ui_description: String ## (Optional) Shown in Hover Panel

@export var facing: Facing.Cardinal = Facing.Cardinal.NORTH

var health: int
@export var starting_health: int

var energy: int
@export var starting_energy: int

var action_count: int

@export_category("Status Effects:")
@export var status_effects: Array[Status]
func get_status_effects() -> Array[Status]:
	return status_effects

#region STATIC METHODS

static func get_global_position_at(map: TileMapLayer, coords: Vector2i) -> Vector2:
	return map.to_global(map.map_to_local(coords))
	
#endregion


func setup(director_: Director, tilemap: TileMapLayer) -> void:
	self.director = director_
	self.tile_map = tilemap
	
	tree_exited.connect(self.director.actors.erase.bind(self))
	
	snap_to_nearest_tile()

	facing = Facing.Cardinal.NORTH
	show_debug_facing_indicator()

	if action_queue:
		action_queue.free()
	action_queue = ActionQueue.new()
	action_queue.setup(self)
	
	if status_manager:
		status_manager.free()
	status_manager = StatusManager.new(self)
	
	if persistent_data_key:
		persistent_actor_data = PlayerData.get_actor_data(persistent_data_key)
		if persistent_actor_data:
			set_stats_from_data()
		else:
			persistent_actor_data = PersistentActorData.new()
			persistent_actor_data.set_stats_from_actor(self, true)
			#PlayerData.set_actor_data(persistent_data_key, persistent_actor_data)
			## We could register right away, but I think it's better to only do it when we finish a level.
			## See method push_persistent_data().
		
	health = starting_health
	energy = starting_energy
	
	update_healthbar()
	
func on_turn_start() -> void: ## Called by Director
	reset_energy()
	reset_action_count()
	status_manager.on_turn_start()
	
func on_turn_end() -> void: ## Called by Director
	status_manager.on_turn_end()

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
	action_count += 1
	action_queue.run_action(action)

func clear_action_queue() -> void:
	action_queue.clear_queue()
	
func _on_action_queue_finished() -> void:
	if emit_actions_finished_signal:
		queued_actions_finished.emit(self)

func reset_action_count() -> void:
	action_count = 0
	
func play_sfx(sound: ActorSfxHandler.Sounds) -> void:
	if sfx:
		sfx.play(sound)

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
	
	#var distance_covered: float = (global_position - get_global_position_at(map, coords)).length()
	var duration_of_movement: float = 0.5 # * distance_covered
	move_tween.tween_property(self, ^"global_position", get_global_position_at(map, coords), duration_of_movement)
	move_tween.tween_callback(animation_finished.emit)
	
	play_sfx(ActorSfxHandler.Sounds.MOVE)

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
			
func select_facing() -> void:
	pass
		
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


class DamageResult:
	var negated: int
	var direct: int
	
	func _init(_negated: int = 0, _direct: int = 0) -> void:
		negated = _negated
		direct = _direct


func take_damage(damage: int) -> DamageResult:
	if debug:
		p("%s incoming damage" % [damage])
	
	##loop through status effects to recalculate damage result
	var unblocked_damage = status_manager.on_take_damage(damage)
	var damage_result := DamageResult.new(damage - unblocked_damage, take_direct_damage(unblocked_damage))
	
	return damage_result
	
func take_direct_damage(damage: int) -> int:
	var damage_result: int = status_manager.on_take_direct_damage(damage)
	
	if debug:
		p("%s incoming direct damage." % [damage_result])
		
	if damage_result > 0:
		play_sfx(ActorSfxHandler.Sounds.GET_HIT)
	
	health -= damage_result
	health = maxi(0, health)
	update_healthbar()
	
	if health <= 0:
		die()
		
	return damage_result


func die() -> void:
	if debug:
		p("Died!")
	## TODO
	Juice.fade_out(self).tween_callback(queue_free)

#endregion

func _on_dealing_damage(damage: int) -> int:
	var changed_damage: int = status_manager.on_deal_damage(damage)
	return changed_damage
	
func _on_dealing_direct_damage(damage: int) -> int: ## TODO TODO TODO TODO
	var changed_damage: int = status_manager.on_deal_direct_damage(damage)
	return changed_damage

func _on_damage_dealt(damage_result: DamageResult) -> void:
	if damage_result.negated > 0:
		status_manager.on_damage_dealt(damage_result.negated)
	if damage_result.direct > 0:
		status_manager.on_direct_damage_dealt(damage_result.direct)

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

func add_status(status: Status) -> void:
	status_manager.add_status(status)
	
func remove_status(status: Status) -> void:
	status_manager.remove_status(status)

#endregion

#region Highlighting & Planning

func get_action_target_cells(action: Action) -> Array[Vector2i]:
	if "pattern" in action:
		if action.is_obstructable == true:
			return get_translated_pattern_without_obstructions(action.pattern) #find cells without actors in them 
		else: 	
			return get_translated_pattern(action.pattern)
	else:
		return get_translated_pattern(Action.NO_PATTERN)

func get_translated_pattern(pattern: Array[Vector2i]) -> Array[Vector2i]:
	return Facing.get_target_cells(current_tile_coords, facing, pattern)

func get_translated_pattern_without_obstructions(pattern: Array[Vector2i]) -> Array[Vector2i]:
	var pat: Array[Vector2i]
	pat = Facing.get_target_cells(current_tile_coords, facing, pattern) #gets global coords
	
	var valid: Array[Vector2i]
	#adds to valid if no actor is found  
	for tile in pat:
		if Level.get_actor_at(tile) != null:
			continue
		valid.append(tile)
	return valid

#endregion
