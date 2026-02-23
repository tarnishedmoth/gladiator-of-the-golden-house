class_name AIActor extends Actor

@export var usable_actions: Array[Action] ## TEST

func queue_new_actions_for_next_turn(claimed_tiles: Array[Vector2i] = []) -> void:
	var queue: Array[Action]

	var to_queue: int = 1
	for i in to_queue:
		queue.append(choose_action(claimed_tiles))

	append_actions_to_queue(queue)

func choose_action(claimed_tiles: Array[Vector2i]) -> Action:
	## Selection
	var action: Action
	if not usable_actions.is_empty():
		action = usable_actions.pick_random().duplicate() ## FIXME HACK: random
	else:
		push_error("No usable actions configured!")
		return null

	## per-action planning
	plan_action_details(action, claimed_tiles)

	return action

func plan_action_details(action: Action, claimed_tiles: Array[Vector2i]) -> void:
	if action is ActionMove:
		## FIXME HACK: Random facing -- should face toward destination.
		var facing_direction: Facing.Cardinal = Facing.Cardinal.values().pick_random()
		set_facing(facing_direction)

		var coords: Vector2i
		var candidates: Array[Vector2i] = []

		if not action.pattern.is_empty():
			candidates = get_translated_pattern(action.pattern)
			candidates = _filter_move_candidates(candidates, claimed_tiles)

			if not candidates.is_empty():
				coords = candidates.pick_random() ## FIXME HACK: random
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

			candidates = _filter_move_candidates(candidates, claimed_tiles)

			if not candidates.is_empty():
				coords = candidates.pick_random() ## FIXME HACK: random
			else:
				coords = self.current_tile_coords
				if debug: p("No valid move target found, staying in place.")

		claimed_tiles.append(coords)
		action.set_target(coords)


## Returns only tiles from [param candidates] that are not occupied by any actor
## and not already claimed by another AI actor's plan this turn.
func _filter_move_candidates(candidates: Array[Vector2i], claimed_tiles: Array[Vector2i]) -> Array[Vector2i]:
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
		valid.append(tile)
	if debug: p("Valid move candidates: %s" % str(valid))
	return valid
