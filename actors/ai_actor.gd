class_name AIActor extends Actor

## Base class for actors with AI behaviors. Extend this class and override its methods to implement
## unique behaviors. This base implementation simply picks randomly from its list of usable actions.

const DO_NOTHING_ACTION: Resource = preload("res://actions/action_do-nothing.gd")

@export var drop_chance:float = 0.0

enum MoveBehavior { ## Determines target tiles during [method plan_action_details] for ActionMoves.
	TO_TARGET,
	RANDOM
}

enum ActionSelection {
	RANDOM,
	POP_QUEUE, ## Shuffles all usable actions into a list, then uses those actions in order until all actions have been used.
	NO_REPEATS,
	CQC, ## Uses Combat moves exclusively when adjacent to a hostile, and non-combat exclusively otherwise.
	CQC_NO_REPEATS, ## Prevents repeats if there are usable alternatives in the action category.
	POP_QUEUE_SEQUENTIAL, ## Similar to POP QUEUE but does not shuffle, looping all actions in order.
}

@export var usable_actions: Array[Action]
@export var actions_to_queue_this_turn: int = 1
@export var action_preview: ActionPreview ## DEPRECATED functionality has been merged into [Actor], see [method Actor.render_preview_for_action].

@export_group("Behaviors")
@export var always_prioritize_nearest_hostile: bool = true
@export var move_behavior:MoveBehavior = MoveBehavior.TO_TARGET
@export var selection_behavior:ActionSelection = ActionSelection.NO_REPEATS

## this is simple, does not consider attack action pattern TODO
## DEPRECATED: Use [member move_behavior] instead of move_towards_target
@export var move_towards_target: bool = true

var hostile_target: Actor ## Used for planning

var _action_pop_queue: Array[Action] = []
var _last_action_picked: Action
var _set_facing_direction_after_planning: Variant ## 

func replace_usable_actions(new_usable_actions: Array[Action], change_queue_size: int = -1) -> void:
	usable_actions.clear()
	usable_actions.append_array(new_usable_actions)
	if change_queue_size > -1:
		actions_to_queue_this_turn = change_queue_size

## This is the planning phase of turn taking, it is run by the director after actions are finished executing.
## We pick actions and plan them one at a time until we have a list as long as [member actions_to_queue_this_turn]...
func queue_new_actions_for_next_turn(claimed_tiles: Array[Vector2i] = []) -> void:
	if debug:
		p("standing at %s, facing %s." % [current_tile_coords, facing])
	
	if actions_to_queue_this_turn == 0:
		append_action_to_queue(DO_NOTHING_ACTION.duplicate())
	for i in actions_to_queue_this_turn:
		append_action_to_queue(choose_action(claimed_tiles))


func choose_action(claimed_tiles: Array[Vector2i], list_of_usable_actions: Array[Action] = usable_actions) -> Action:
	## Selection
	var action: Action
	if list_of_usable_actions.is_empty():
		push_error("No usable actions configured!")
		return null
	
	match selection_behavior:
		ActionSelection.RANDOM:
			action = list_of_usable_actions.pick_random()
		
		ActionSelection.POP_QUEUE:
			if _action_pop_queue.is_empty():
				_action_pop_queue.append_array(list_of_usable_actions)
				_action_pop_queue.shuffle()
			action = _action_pop_queue.pop_front()
			
		ActionSelection.POP_QUEUE_SEQUENTIAL:
			if _action_pop_queue.is_empty():
				_action_pop_queue.append_array(list_of_usable_actions)
			action = _action_pop_queue.pop_front()
			
		ActionSelection.NO_REPEATS:
			var _filtered: Array[Action] = list_of_usable_actions.filter(func(v: Action): return not v == _last_action_picked)
			if _filtered.is_empty():
				push_warning("No usable actions after filtering! Fallback to random...")
				action = list_of_usable_actions.pick_random() ## fallback
			else:
				action = _filtered.pick_random()
		
		ActionSelection.CQC, ActionSelection.CQC_NO_REPEATS:
			var surrounding_tiles: Array[Vector2i] = tile_map.get_surrounding_cells(current_tile_coords)
			var is_near: bool = false
			
			for tile in surrounding_tiles:
				var actor_on_tile: Actor = Level.get_actor_at(tile)
				if actor_on_tile:
					if actor_on_tile.director != director:
						is_near = true
						break
			
			var _filtered: Array[Action]
			if is_near:
				## Hostile actor in surrounding tiles
				if debug: p("(CQC) Found hostile actor in adjacent tile.")
				_filtered = list_of_usable_actions.filter(func(v: Action): return v.action_category == Action.ActionCategory.COMBAT)
			else:
				## No hostile actor in surrounding tiles
				if debug: p("(CQC) Did not find any hostile actors in adjacent tiles.")
				_filtered = list_of_usable_actions.filter(func(v: Action): return v.action_category != Action.ActionCategory.COMBAT)
			
			if _filtered.is_empty():
				if debug: p("No usable actions after filtering! Sampling from all actions...")
				_filtered = list_of_usable_actions.duplicate()
				
			if selection_behavior == ActionSelection.CQC_NO_REPEATS:
				var _no_repeats: Array[Action] = _filtered.filter(func(v: Action): return not v == _last_action_picked)
				if not _no_repeats.is_empty():
					_filtered = _no_repeats
				else:
					if debug: p("No unrepeated actions found.")
			
			action = _filtered.pick_random()
	
	_last_action_picked = action
	action = action.duplicate()
	if debug: p("Picked action %s" % action)
	
	## per-action planning
	plan_action_details(action, claimed_tiles)
	return action
	
func get_facing_direction_to_hostile_target() -> Facing.Cardinal:
	if not hostile_target:
		return facing
	else:
		return Facing.get_direction_to_cell(tile_map, current_tile_coords, hostile_target.current_tile_coords)

func plan_action_details(action: Action, claimed_tiles: Array[Vector2i]) -> void:
	action.set_actor(self)
	if not hostile_target: choose_hostile_target()
	
	if action is ActionMove:
		if debug: p("Planning ActionMove.")
		
		if action.allow_facing_before:
			var facing_direction: Facing.Cardinal
			if hostile_target:
				facing_direction = get_facing_direction_to_hostile_target()
			else:
				## Fallback but should never run in gameplay
				facing_direction = Facing.Cardinal.values().pick_random()
			set_facing(facing_direction)

		var coords: Vector2i
		var candidates: Array[Vector2i] = []

		if not action.pattern.is_empty():
			candidates = get_translated_pattern(action.pattern)
			
			if action is ActionMoveKnockback:
				if hostile_target.current_tile_coords in candidates:
					coords = hostile_target.current_tile_coords
					claimed_tiles.append(coords)
					action.set_target(coords)
					return
			
			candidates = _filter_move_candidates(candidates, claimed_tiles, action.is_obstructable)

			if not candidates.is_empty() && hostile_target:
				match move_behavior: ## TBD: Expand here any time new MoveBehaviors are added
					MoveBehavior.TO_TARGET:
						## Move in a direction towards the target
						candidates.sort_custom(sort_hostile_distance)
						coords = candidates.front()
					MoveBehavior.RANDOM:
						coords = candidates.pick_random()
					_: ## Default to random if MoveBehavior is not yet handled
						coords = candidates.pick_random()
						if debug: p("MoveBehavior %s is unhandled, picking random instead." % MoveBehavior.find_key(move_behavior))
			elif not candidates.is_empty() && not hostile_target:
					coords = candidates.pick_random()
			else:
				coords = self.current_tile_coords
				if debug: p("No valid move target found, staying in place.")

		else:
			## DEPRECATED distance-based fallback (all prefabs use patterns)
			var distance: int = randi_range(action.distance.x, action.distance.y) ## FIXME HACK: random
			var surrounding: Array[Vector2i] = tile_map.get_surrounding_cells(self.current_tile_coords)
			for neighbor in surrounding:
				var offset: Vector2i = neighbor - self.current_tile_coords
				var destination: Vector2i = self.current_tile_coords + offset * distance
				candidates.append(destination)

			candidates = _filter_move_candidates(candidates, claimed_tiles, action.is_obstructable)

			if not candidates.is_empty():
				coords = candidates.pick_random() ## FIXME HACK: random
			else:
				coords = self.current_tile_coords
				if debug: p("No valid move target found, staying in place.")

		claimed_tiles.append(coords)
		action.set_target(coords)


	elif action is ActionAttack:
		if action.allow_facing_before:
			set_facing(get_facing_direction_to_hostile_target())
		
		if not action.aoe_pattern:
			## We can hit every tile
			if debug: p("Skipping ActionAttack planning (Action does not use AoE).")
			return

		if debug: p("Planning ActionAttack.")

		var potential_targets: Array[Vector2i] = get_action_target_cells(action) ## Absolute coords
		var _potential_affected: Dictionary[Vector2i, Array] ## Absolute target coord, absolute aoe tiles

		potential_targets = potential_targets.filter(TileInteractor.cell_exists.bind(tile_map))

		if potential_targets.is_empty():
			## No valid choices for this action
			var string: String = "Did not configure action %s due to no valid moves." % action
			if debug: p(string)
			push_warning(string)
			return

		if not hostile_target:
			if debug: p("Randomizing ActionAttack planning (no hostile target).")
			action.set_target(potential_targets.pick_random())
			return

		for coord in potential_targets:
			if action.aoe_pattern:
				var affected: Array[Vector2i]= Facing.get_target_cells(
					coord,
					facing,
					action.aoe_pattern
					)
				_potential_affected[coord] = affected
			else:
				_potential_affected[coord] = [coord]

		if debug: p("Target candidates: %s" % [potential_targets])

		var choice_target = null ## Absolute

		for target: Vector2i in _potential_affected.keys():
			if hostile_target.current_tile_coords in _potential_affected[target]:
				## Target in AoE
				choice_target = target
				break

		if choice_target == null:
			## Sort by distance
			## It's honestly safe to assume that the target coord itself is a good approximation--
			## no need to iterate through every single affected AoE tile.
			potential_targets.sort_custom(sort_hostile_distance)
			choice_target = potential_targets.front()
			if debug: p("Closest target to hostile is %s." % [choice_target])
		else:
			if debug: p("Hostile target within AoE for %s." % [choice_target])

		assert(choice_target != null)
		if debug:
			## Sanity check
			assert(choice_target in Facing.get_target_cells(current_tile_coords, facing, action.pattern))
			if debug: p("Verified target choice is valid.")

		action.set_target(choice_target)
	
	elif action is ActionSpawn:
		if action.allow_facing_before:# or action.allow_facing_after:
			set_facing(get_facing_direction_to_hostile_target())
		
		## Pick a valid tile to spawn at
		var choice_target: Vector2i
		
		if action.pattern.is_empty():
			if debug: p("ActionSpawn has no pattern, skipping planning.")
			return
		
		var potential_targets: Array[Vector2i] = _filter_move_candidates(get_action_target_cells(action), claimed_tiles, false)
		if potential_targets.is_empty():
			if debug: p("No valid potential targets, skipping planning.")
			return
		
		potential_targets.sort_custom(sort_hostile_distance)
		choice_target = potential_targets.front()
		claimed_tiles.append(choice_target)
		
		action.set_target(choice_target)
	
	elif action is ActionApplyStatusPattern:
		if action.pattern != null:
			if action.pattern.size() > 1:
				## TODO not implemented
				push_warning("Target selection for %s (ActionApplyStatusPattern) not implemented!" % action)
				pass
			
			else:
				if debug: p("%s does not require planning." % action)
			
	elif action is ActionApplyStatus:
		if debug: p("%s does not require planning." % action)
	
	else:
		push_warning("Unconfigured planning behavior for action %s subclass!" % action)


func die()->void:
	if drop_chance: # null check
		if not is_zero_approx(drop_chance): # addtl zero check
			var pick_up_manager: PickUpManager = Level.get_pickup_manager()
			if pick_up_manager:
				if randf() < drop_chance:
					var picked_item = pick_up_manager.get_weighted_random()
					if picked_item != null:
						pick_up_manager.spawn_pick_up(picked_item,current_tile_coords)
	super()

## Given two coordinates, returns the one closer to [member hostile_target.current_tile_coords].
func sort_hostile_distance(a: Vector2i, b: Vector2i) -> bool:
	## Must convert to global position due to coordinates not being square.
	var _a: Vector2 = get_global_position_at(tile_map, a)
	var _b: Vector2 = get_global_position_at(tile_map, b)
	var _hostile: Vector2 = get_global_position_at(tile_map, hostile_target.current_tile_coords)
	return \
	_a.distance_squared_to(_hostile) < \
	_b.distance_squared_to(_hostile)

## Assigns an Actor to [member hostile_target].
## If [member always_prioritize_nearest_hostile] it will be the nearest by tile coordinate.
## Otherwise, it will be random.
## WARNING HACK FIXME THIS IS IMPLEMENTED INCORRECTLY
## CANT USE HEX COORDS FOR COMMON SQUARE GRID DISTANCE CALCULATIONS
func choose_hostile_target() -> void:
	## Lets find an enemy actor to target
	var available_targets: Array[Actor]
	for _director in Level.get_directors():
		if _director != director: ## assume all other directors are hostile
			available_targets.append_array(_director.actors)

	if director is AIDirector: ## should be a given but for static typing sake
		if director.allied_with_player:
			## Remove player characters from the list
			available_targets = available_targets.filter(
				func(v: Actor): return false if v.director is Player else true
			)

	if available_targets.is_empty():
		push_warning("No hostile actors found")
		hostile_target = null
		return
	elif available_targets.size() != 1:
		if always_prioritize_nearest_hostile:
			## Sort the array by nearest
			available_targets.sort_custom(
				func(a: Actor, b: Actor) -> bool: return \
				current_tile_coords.distance_squared_to(a.current_tile_coords) < \
				current_tile_coords.distance_squared_to(b.current_tile_coords)
			)
		else:
			## Random
			available_targets.shuffle()
	hostile_target = available_targets.front()
	if debug: p("Chose hostile target: %s" % [hostile_target])


## Returns only tiles from [param candidates] that are not occupied by any actor
## and not already claimed by another AI actor's plan this turn.
func _filter_move_candidates(candidates: Array[Vector2i], claimed_tiles: Array[Vector2i], is_obstructable: bool) -> Array[Vector2i]:
	var valid: Array[Vector2i] = []
	for tile in candidates:
		if tile == self.current_tile_coords:
			continue
		if not TileInteractor.cell_exists(tile, self.tile_map):
			if debug: p("Rejected %s (off map)" % tile)
			continue
		if Level.get_actor_at(tile) != null:
			if debug: p("Rejected %s (occupied)" % tile)
			continue
		if tile in claimed_tiles:
			if debug: p("Rejected %s (claimed by another AI)" % tile)
			continue
		if is_obstructable:
			var result: Vector2i = find_last_unobstructed_tile(current_tile_coords, tile)
			if result != tile:
				continue
		valid.append(tile)
	if debug: p("Valid move candidates: %s" % str(valid))
	return valid

func preview_ai_attack()-> void:
	#for each action in actions queue might need to duplcate so I dont use
	#for action in action_queue.queue:
		#action_preview.show_preview_action(action)

	## OK let's be honest, only the first action really needs to be rendered.
	## Reason being, the second action is typically either movement, or it depends on the result of the first action.
	## Rather than trying to design a way to step through every action
	## Let's settle for the first action and leave the other ones to the player's purview
	if action_queue.queue.is_empty():
		return
	var first_action: Action = action_queue.queue.front()
	if first_action:
		render_preview_for_action(first_action, first_action._target)

#func hide_preview_attack()-> void: ## DEPRECATED merged into [Actor]
	#action_preview.hide_preview_action()

## This is checked/enforced in [method queue_new_actions_for_next_turn].
func set_facing_after_planning(cardinal_direction: Facing.Cardinal) -> void:
	_set_facing_direction_after_planning = cardinal_direction

## NOTICE It's very important that you set facing only *after* the queue has been populated.
## If you set facing while populating the queue, targets can become corrupted.
func set_facing(cardinal_direction: Facing.Cardinal) -> void:
	var difference = Facing.get_relative_direction(facing, cardinal_direction)
	if difference > 0:
		if debug: p("Set facing: %s is incoming cardinal, %s existing, [b]difference is %s[/b]." % [cardinal_direction, facing, difference])
		rotate_all_actions_by(difference)
	super(cardinal_direction)

## This method is responsible for updating queued actions when we are moved by external forces.
func move_to_tile(coords: Vector2i, duration_of_movement: float = 0.4) -> void:
	var _starting_coord: Vector2i = current_tile_coords
	super(coords, duration_of_movement)
	var _ending_coord: Vector2i = current_tile_coords
	if _starting_coord != _ending_coord:
		move_all_actions_by(_ending_coord - _starting_coord)

func move_all_actions_by(offset: Vector2i) -> void:
	if get_action_queue().queue.is_empty():
		return
	if debug: p("Nudging all queued actions' targets by %s..." % offset)
	for action in get_action_queue().queue:
		if action == self: continue
		if action._target != null:
			action.set_target(action._target + offset)
			if debug: p("Nudged %s." % action)
		else:
			if debug: p("%s has a null target, not nudging." % action)

## Provide the result of Facing.get_relative_direction() as the param.
func rotate_all_actions_by(difference: Facing.Relative) -> void:
	if get_action_queue().queue.is_empty():
		return
	if debug: p("Rotating all queued actions' targets by %s..." % difference)
	for action in get_action_queue().queue:
		if action == self: continue
		if action._target != null:
			var old_target: Vector2i = action._target
			var new_target: Vector2i = Facing.rotate_absolute_coords_around_pivot(current_tile_coords, old_target, difference)
			if debug: p("Rotated absolute target %s from %s to %s." % [action, old_target, new_target])
			action.set_target(new_target)
