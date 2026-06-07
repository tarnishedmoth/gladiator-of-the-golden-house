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

## Signals
signal animation_finished
signal queued_actions_finished(actor: Actor)

## Type constants
const RENDER_AI_PLAYABLE_TILES: bool = false ## Set to true to render grey tiles for unselected playable target tiles of ai action previews
const SHOW_FACING_INDICATOR: bool = true

## Filesystem constants
const FACING_INDICATOR_SCENE = preload("uid://b3kl75n4nwdge")
const DEFAULT_VFX_HANDLER = preload("uid://l1r068mo4353")

## Enums

## Export properties
@export var character_visual_root: Node2D ## The sprite. Right-facing is the correct default direction.
@export var facing_direction_affects_visual: bool = true ## If true, the [member character_visual_root] will be x-scale flipped for left facing.

@export var health_bar: Healthbar
@export var speech_bubble: DialogueBubble

@export var label_anchor: Vector2 = Vector2(0, -40)

@export_group("Sprite Anchors")
@export var anchor_hand: Marker2D:
	set(v):
		anchor_hand = v
		_callback_anchor_waiters()


## Save / Load
## See [PersistentActorData] for the snapshot type and serialization.
var persistent_actor_data: PersistentActorData
@export_group("Persistent Data", "persistent_")
@export var persistent_data_key: StringName ## Only for story characters (player, etc)


## Restores persistent state captured by a previous level's [method push_persistent_data].
## Bypasses the entire [StatusManager] pipeline (no HUD popup, no `vfx_applied` particles,
## no `on_applying_status` mutation interactions). Restoration is conceptually different
## from live application — the saved snapshot IS the truth, applied as-is.
## Stash is restored separately by [method Player.setup].
func apply_persistent_data(data: PersistentActorData) -> void:
	assert(data)
	max_health = data.max_health
	health = data.current_health
	starting_energy = data.starting_energy
	energy = starting_energy  ## Keep `energy` in sync until first on_turn_start.

	status_effects.clear()
	for s in data.status_effects:
		## Detach from the saved snapshot in PlayerData.persistent_actors[...] —
		## otherwise the first turn tick mutates the snapshot too, eroding state per round-trip.
		var copy: Status = s.duplicate()
		SaveUid.tag_duplicate(s, copy)
		copy.set_actor(self)
		status_effects.append(copy)


func push_persistent_data() -> void:
	if persistent_data_key:
		assert(persistent_actor_data)
		persistent_actor_data.capture_from_actor(self)
		PlayerData.set_actor_data(persistent_data_key, persistent_actor_data)


@export var ui_name: String ## Shown in Hover Panel
@export var ui_subtitle: String ## (Optional) Shown in hover panel
@export_multiline() var ui_description: String ## (Optional) Shown in Hover Panel

@export var facing: Facing.Cardinal = Facing.Cardinal.NORTH

var health: int
@export var max_health: int

var energy: int
@export var starting_energy: int

## Directional multipliers for incoming damage
@export_group("Directional Vulnerability", "dm_")
@export var dm_dmg_f: float = 1.0 ## mult for the relative forward direction
@export var dm_dmg_fr: float = 1.0 ## mult for the relative forward right direction
@export var dm_dmg_rr: float = 1.5 ## mult for the relative rearward right direction
@export var dm_dmg_r: float = 2.0 ## mult for the relative rearward direction
@export var dm_dmg_rl: float = 1.5 ## mult for the relative rearward left direction
@export var dm_dmg_fl: float = 1.0 ## mult for the relative forward left direction

@export_category("Status Effects:")
@export var status_effects: Array[Status]
func get_status_effects() -> Array[Status]:
	return status_effects

## Variable data
var emit_actions_finished_signal: bool = false
var current_tile_coords: Vector2i
var previous_tile_coords: Vector2i

var action_count: int
var incoming_damage_by: WeakRef
func clear_incoming_damage_by() -> void: incoming_damage_by = null
func get_incoming_damage_by() -> Actor:
	return incoming_damage_by.get_ref() if incoming_damage_by is WeakRef else null

## Variable objects
var facing_indicator: Node2D ## instantiated at runtime

var tile_map: TileMapLayer
var director: Director

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

var vfx: ActorVfxHandler
func get_vfx_handler() -> ActorVfxHandler:
	assert(vfx)
	return vfx

#region STATIC METHODS

static func get_global_position_at(map: TileMapLayer, coords: Vector2i) -> Vector2:
	return map.to_global(map.map_to_local(coords))
	
#endregion


func setup(director_: Director, tilemap: TileMapLayer) -> void:
	self.director = director_
	self.tile_map = tilemap
	#tree_exited.connect(self.director.actors.erase.bind(self)) ## moved to die() for more explicit control
	_reorient_to_level_rotation() ## Also snaps
	
	if SHOW_FACING_INDICATOR:
		show_facing_indicator()

	if action_queue:
		action_queue.free()
	action_queue = ActionQueue.new()
	action_queue.setup(self)
	
	if status_manager:
		status_manager.free()
	status_manager = StatusManager.new(self)
	
	if not vfx:
		vfx = DEFAULT_VFX_HANDLER.instantiate()
		add_child(vfx)
	
	health = max_health
	energy = starting_energy
	
	if persistent_data_key:
		persistent_actor_data = PlayerData.get_actor_data(persistent_data_key)
		if persistent_actor_data:
			apply_persistent_data(persistent_actor_data)
		else:
			persistent_actor_data = PersistentActorData.new()
			persistent_actor_data.capture_from_actor(self)
			## We register persistent data only when a level is finished. See [method push_persistent_data].
		
	#if speech_bubble:
		#speech_bubble.speak("!!")
	
	update_healthbar()
	
func on_turn_start() -> void: ## Called by Director
	reset_energy()
	reset_action_count()
	status_manager.on_turn_start()
	
	
func on_turn_end() -> void: ## Called by Director
	status_manager.on_turn_end()
	
#region Weapon Anchors

var _anchors_to_call: Array[WeaponAnchorer]

## Calls the callable [param callback] and passes the weapon anchor as an argument.
func subscribe_weapon(weapon: WeaponAnchorer) -> void:
	if anchor_hand:
		weapon.set_anchor(anchor_hand)
	else:
		_anchors_to_call.append(weapon)
		
func register_anchor(node: Node2D) -> void:
	if debug:
		p("Registered weapon anchor %s" % node)
	anchor_hand = node
	
func _callback_anchor_waiters() -> void:
	for s in _anchors_to_call:
		if is_instance_valid(s):
			s.set_anchor(anchor_hand)

#endregion
#region ACTIONS

func run_queued_actions() -> void: ## Emits a signal when done.
	emit_actions_finished_signal = true
	action_queue.run_queue()

func queue_action(action: Action, and_run_queue: bool = false) -> void:
	action_queue.queue.append(action)
	action_count += 1
	if and_run_queue:
		run_queued_actions()
		
func append_actions_to_queue(array: Array[Action]) -> void:
	action_count += array.size()
	action_queue.queue.append_array(array)

func run_action(action: Action) -> void: ## Immediately runs one action (and any chained actions).
	if action_queue.running_queue:
		push_warning("Action queue is apparently running the queue / Check for bad state?")
	action_count += 1
	action_queue.run_action(action)

func clear_action_queue() -> void:
	action_count -= action_queue.queue.size()
	action_queue.clear_queue()
	
func _on_action_queue_finished() -> void:
	if emit_actions_finished_signal:
		queued_actions_finished.emit(self)

func reset_action_count() -> void:
	action_count = 0
	
func play_sfx(sound: ActorSfxHandler.Sounds) -> void:
	if sfx:
		sfx.play(sound)

func spawn_vfx(effect: ActorVfxHandler.FX) -> void:
	if vfx:
		vfx.play(effect)


#endregion

#region MOVEMENT & FACING

func _reorient_to_level_rotation() -> void:
	var original: Vector2i = tile_map.local_to_map(tile_map.to_local(global_position))
	assert(tile_map.get_cell_tile_data(original))
	
	facing = Level.get_starting_facing(facing)
	var actual: Vector2i = Level.get_starting_coord(original)
	
	global_position = get_global_position_at(tile_map, actual)
	current_tile_coords = actual

func snap_to_nearest_tile() -> void:
	var tile_coords: Vector2i = tile_map.local_to_map(tile_map.to_local(global_position))
	assert(TileInteractor.cell_exists(tile_coords, tile_map))
	global_position = get_global_position_at(tile_map, tile_coords)
	
	current_tile_coords = tile_coords

func move_to_tile(coords: Vector2i, duration_of_movement: float = 0.5) -> void:
	if not tile_map:
		push_error("tile_map is invalid.")
		return

	## Prevent moving onto a tile occupied by another actor
	var occupant: Actor = Level.get_actor_at(coords)
	if occupant != null and occupant != self:
		push_warning("Actor %s tried to move to %s but it is occupied by %s. Staying in place." % [name, coords, occupant.name])
		await create_tween().tween_interval(0.1).finished
		animation_finished.emit()
		return

	previous_tile_coords = current_tile_coords
	current_tile_coords = coords
	var move_tween := create_tween()
	move_tween.set_trans(Tween.TRANS_QUAD)
	
	#var distance_covered: float = (global_position - get_global_position_at(map, coords)).length()
	#var duration_of_movement: float = 0.5 # * distance_covered
	move_tween.tween_property(self, ^"global_position", get_global_position_at(tile_map, coords), duration_of_movement)
	move_tween.tween_callback(animation_finished.emit)
	
	play_sfx(ActorSfxHandler.Sounds.MOVE)
	
	if(director is Player):
		var pickup: PickUp = Level.get_pick_up_at(coords)
		if pickup:
			pickup.on_pick_up(self)
		

## Sets [member facing]. North is the default value.
func set_facing(cardinal_direction: Facing.Cardinal) -> void:
	if not cardinal_direction in Facing.Cardinal.values():
		push_error("Out of bounds")
	else:
		facing = cardinal_direction
	
	## flipping the character sprites -- thanks McFunkypants
	if character_visual_root and facing_direction_affects_visual:
		# flip if facing down or west (assume sprite faces right)
		character_visual_root.scale.x = -1 if facing > Facing.Cardinal.SOUTHEAST else 1
	
	if SHOW_FACING_INDICATOR && self.is_inside_tree():
		show_facing_indicator(true)
	
## Returns [member facing]. North is the default value.
func get_facing() -> Facing.Cardinal:
	return facing

func show_facing_indicator(show_: bool = true) -> void:
	if not show_:
		if facing_indicator:
			facing_indicator.free()
	else:
		if not facing_indicator:
			facing_indicator = FACING_INDICATOR_SCENE.instantiate()
			add_child(facing_indicator)
		
		## Set rotation
		var degrees: int = 60 * facing
		facing_indicator.rotation_degrees = degrees
		
		#if debug: ## just spammy
			#p("Facing %s and rotated to %d degrees." % [facing, degrees])


## All-in-one wrapper method for [method get_incoming_damage_face] and [method calculate_direcitonal_damage].
## Provide an [Actor] or [Vector2i] absolute coordinates to get modified damage value
## based on the export properties for directional vulnerability/multipliers. See [member dm_dmg_f].
##
## NOTE: These methods are not used in [Actor]'s take damage methods. It is utilized by [Action]s themselves.
##
func calculate_directional_damage_from(actor_or_absolute_coords: Variant, damage: int) -> int:
	var face: Facing.Relative = get_incoming_damage_face(actor_or_absolute_coords)
	#print("Relative %s to %s" % [face, actor_or_absolute_coords])
	return calculate_directional_damage(damage, face)

## Rounds upwards.
func calculate_directional_damage(damage: int, direction: Facing.Relative) -> int:
	var dm: float
	match direction:
		Facing.Relative.FRONT:
			dm = dm_dmg_f
		Facing.Relative.FRONT_RIGHT:
			dm = dm_dmg_fr
		Facing.Relative.BACK_RIGHT:
			dm = dm_dmg_rr
		Facing.Relative.BACK:
			dm = dm_dmg_r
		Facing.Relative.BACK_LEFT:
			dm = dm_dmg_rl
		Facing.Relative.FRONT_LEFT:
			dm = dm_dmg_fl
		_:
			push_error("Invalid direction returned")
			breakpoint
	return ceili(dm * damage)

## You can provide an [Actor] or [Vector2i]. When given an Actor, it will use the
## [member Actor.current_tile_coords].
func get_incoming_damage_face(actor_or_absolute_coords: Variant) -> Facing.Relative:
	var incoming_coords: Vector2i
	if actor_or_absolute_coords is Actor:
		incoming_coords = actor_or_absolute_coords.current_tile_coords
	elif actor_or_absolute_coords is Vector2i:
		incoming_coords = actor_or_absolute_coords
	elif actor_or_absolute_coords is Vector2:
		push_error("Method was provided Vector2 instead of Vector2i.")
		incoming_coords = Vector2i(actor_or_absolute_coords)
	else:
		push_error("Invalid argument passed to method get_incoming_damage_face().")
		return Facing.Relative.FRONT
	
	var cardinal = Facing.get_direction_to_cell(tile_map, current_tile_coords, incoming_coords)
	var relative = Facing.get_relative_direction(facing, cardinal)
	if debug:
		p("Vulnerability: from %s aka %s, facing %s, direction is %s" % [incoming_coords, cardinal, facing, relative])
	return relative

#endregion

#region HEALTH
func show_healthbar() -> void:
	if health_bar:
		health_bar.show_()
		
func hide_healthbar() -> void:
	if health_bar:
		health_bar.fade_out()

func update_healthbar() -> void:
	if health_bar:
		health_bar.update_healthbar(health, max_health)


class DamageResult:
	var negated: int
	var direct: int
	
	func _init(_negated: int = 0, _direct: int = 0) -> void:
		negated = _negated
		direct = _direct

## This goes through two layers of status effect hook callbacks,
## once for regular damage (on_take_damage),
## and once for direct damage (on_take_direct_damage).
## The result returned is a package of the results after running through all status effects/modifiers.
## For example, a Defense status effect might apply to regular damage (on_take_damage), negating points.
## A piercing attack might deal direct damage, bypassing Defense entirely.
## That is the purpose of these different status effect hooks.
func take_damage(damage: int, from: Actor = null) -> DamageResult:
	if from != null:
		incoming_damage_by = weakref(from)
	else:
		clear_incoming_damage_by()
	
	if debug:
		p("%s incoming damage" % [damage])
	
	##loop through status effects to recalculate damage result
	var unblocked_damage = status_manager.on_take_damage(damage)
	
	var damage_result: Actor.DamageResult = DamageResult.new(
		damage - unblocked_damage,
		## loop through status effects to calculate direct damage result
		take_direct_damage(unblocked_damage) if unblocked_damage > 0 else 0
		)

	if damage_result.negated > 0:
		Level.get_hud().popup_negated(damage_result.negated, self)

	## Return value is used by ActionAttack 
	return damage_result
	
func take_direct_damage(damage: int, from: Actor = null) -> int:
	if from != null:
		incoming_damage_by = weakref(from)
	
	var damage_result: int = status_manager.on_take_direct_damage(damage)
	
	if debug:
		p("%s incoming direct damage." % [damage_result])
		
	if damage_result > 0:
		play_sfx(ActorSfxHandler.Sounds.GET_HIT)
		Level.get_hud().popup_damage(damage_result, self)
		
	if (health - damage_result > 0) && (health - damage_result < health/2.0):
		## not gonna die but it's a heavy hit
		if randf() > 0.6:
			Level.get_instance().trigger_response_speech_bubbles(director is Player)
	
	health -= damage_result
	health = maxi(0, health)
	update_healthbar()
	
	if health <= 0:
		die()
		
	return damage_result

func apply_healing(amount: int, from: Actor = null) -> int:
	if from != null:
		incoming_damage_by = weakref(from)

	var actual_amount: int = mini(amount, max_health - health)
	if debug:
		p("%s applying healing." % [actual_amount])

	if actual_amount > 0:
		# TODO: probably a different sound and popup?
		play_sfx(ActorSfxHandler.Sounds.GET_HIT)
		Level.get_hud().popup_damage(actual_amount, self)

	health += actual_amount
	update_healthbar()

	return actual_amount

func die() -> void:
	if debug:
		p("Died!")
		
	Level.get_instance().trigger_response_speech_bubbles(director is Player)
	
	director.actors.erase(self)
	Juice.fade_out(self).tween_callback(queue_free)

#endregion

func _on_dealing_damage(damage: int) -> int:
	var changed_damage: int = status_manager.on_deal_damage(damage)
	return changed_damage
	
func _on_dealing_direct_damage(damage: int) -> int:
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
## Used to track status effects by a keyword
func erase_keyed_statuses(key) -> void:
	status_manager.remove_keyed_statuses(key)

func add_status(status: Status, key = null) -> void:
	var suffix := " %+d" % status.effect_points if status.effect_points != 0 else ""
	Level.get_hud().popup_status(status.ui_name + suffix, self)
	status_manager.add_status(status, key)
	
func remove_status(status: Status) -> void:
	status_manager.remove_status(status)

#endregion

#region Highlighting & Planning
var _popup_labels: Array[Label]
## Clear highlights and popup labels
func hide_preview_for_actions()->void:
	TargetFinder.clear_target_highlights(self)
	for popup in _popup_labels:
		if is_instance_valid(popup):
			Level.get_hud().clear_popup_persistent_label(popup)
	_popup_labels.clear()


## Renders tile highlights previewing a given action's available tiles and AoE for a selected tile.
## [param target] should be Vector2i
func render_preview_for_action(action: Action, target) -> void:
	var color: Color = Action.get_action_color(action)
	if director is AIDirector:
		if director.allied_with_player:
			## Denote allies
			color = color.lightened(0.4)
	
	## Find targetable tiles (pattern).
	var playable_tiles: Array[Vector2i]
	if not "split_choice" in action:
		playable_tiles = get_action_target_cells(action)
	elif action.split_choice:
		playable_tiles = get_action_target_cells(action, true) ## Include mirrored
	else:
		playable_tiles = get_action_target_cells(action)
	
	if director is Player:
		## Render playable tiles with finesse to show the player how they can interact
		
		## If a target tile is in the playable pattern, ...
		var hovered_tile_is_valid: bool = false
		if target != null:
			hovered_tile_is_valid = target in playable_tiles
			playable_tiles.erase(target) ## maybe don't need this ............... brb
		
		## ... Highlight playable tiles as selectable or not currently selected
		TargetFinder.highlight_targets(
			playable_tiles,
			Color.WHITE if not hovered_tile_is_valid else Targeting.COLORS.GREY,
			self
			)
	else:
		## AI action previews
		#if action is ActionMove:
			#TargetFinder.highlight_targets(playable_tiles, Targeting.COLORS.GREY, self)
		#else:
		if target == null:
			TargetFinder.highlight_targets(playable_tiles, color, self)
		else:
			TargetFinder.highlight_target(target, Targeting.COLORS.PINK, self)
			if RENDER_AI_PLAYABLE_TILES:
				TargetFinder.highlight_targets(playable_tiles, Targeting.COLORS.GREY, self)
	
	## Render AoE pattern if applicable
	if target != null:
		var aoe_tiles = get_action_target_cells_at(target, action)
		for coords in aoe_tiles:
			var found_actor: Actor = Level.get_actor_at(coords)
			
			if found_actor != null:
				if action is ActionAttack:
					_popup_labels.append(Level.get_hud().popup_label_persistent("Damage: %s" % action.damage, found_actor, LevelHUD.STYLE_DAMAGE))
					TargetFinder.highlight_target(coords, Targeting.COLORS.RED, self)
					
				elif action is ActionApplyStatus:
					_popup_labels.append(Level.get_hud().popup_label_persistent("%s: %s" % [action.status.ui_name, action.override_quantity], found_actor, LevelHUD.STYLE_STATUS))
					TargetFinder.highlight_target(coords, Targeting.COLORS.YELLOW, self)
					
				elif action is ActionMove:
					TargetFinder.highlight_target(coords, Targeting.COLORS.PINK, self)
				
				else:
					TargetFinder.highlight_target(coords, color, self)
			else:
				TargetFinder.highlight_target(coords, color, self)
		
		#if aoe_tiles != null:
			#TargetFinder.highlight_aoe_spots(
				#aoe_tiles,
				#color,
				#self
				#)


## Updated method to work with AoE patterns, original pattern is assumed to be just for selection.
## Does check if the play tile is a valid playable tile.
func get_action_target_cells_at(play_tile: Vector2i, action: Action) -> Array[Vector2i]:
	var aoe: Array[Vector2i]
	if not "pattern" in action:
		if current_tile_coords == play_tile:
			aoe.append(current_tile_coords)
		return aoe
	
	var valid_cells := Facing.get_target_cells(current_tile_coords, facing, action.pattern)
	if not play_tile in valid_cells:
		## Invalid play tile
		#if debug: p("get_action_target_cells_at: Invalid play tile %s in %s." % [play_tile, valid_cells]) ## print spam
		return aoe
	
	if not "aoe_pattern" in action:
		aoe = Action.NO_PATTERN
	else:
		aoe = action.aoe_pattern
	
	var _facing = get_facing()
	return Facing.get_target_cells(play_tile, _facing, aoe)

func get_action_target_cells(action: Action, include_mirrored: bool = false) -> Array[Vector2i]:
	if "pattern" in action:
		var result: Array[Vector2i]
		
		if action.is_obstructable == true:
			result = get_translated_pattern_without_obstructions(action.pattern) #find cells without actors in them 
			if include_mirrored:
				result.append_array(get_translated_pattern_without_obstructions(
					Facing.mirror(action.pattern))
					)
			
		else:
			result = get_translated_pattern(action.pattern)
			if include_mirrored:
				result.append_array(get_translated_pattern(
					Facing.mirror(action.pattern))
					)
		
		return result
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
	
func on_hovered() -> void:
	show_healthbar()
	
func on_unhovered() -> void:
	hide_healthbar()

#endregion
