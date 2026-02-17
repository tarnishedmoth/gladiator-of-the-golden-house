class_name AIActor extends Actor

@export var usable_actions: Array[Action] ## TEST

func queue_new_actions_for_next_turn() -> void:
	var queue: Array[Action]
	
	var to_queue:int = 1
	for i in to_queue:
		queue.append(choose_action())
		
	append_actions_to_queue(queue)

func choose_action() -> Action:
	## Selection
	var action: Action
	if not usable_actions.is_empty():
		action = usable_actions.pick_random().duplicate() ## FIXME HACK: random
	else:
		push_error("No usable actions configured!")
		return null
	
	## per-action planning
	plan_action_details(action)
	
	return action

func plan_action_details(action: Action) -> void:
	var actors: Array[Actor] = Level.get_all_actors_in_play_order()
	
	var facing_direction: Facing.Cardinal
	
	if action is ActionMove:
		## We have to plan how to utilize our movement action.
		
		var coords: Vector2i
		if not action.pattern.is_empty():
			## Pick from available movement tiles:
			coords = action.pattern.pick_random() ## FIXME HACK: random
			
		else:
			## Any direction by distance
			## Pick a distance
			var distance: int = randi_range(action.distance.x, action.distance.y) ## FIXME HACK: random
			
			## This gives us open directions but only guarantees the existence of the next neighbor cell.
			var surrounding: Array[Vector2i] = tile_map.get_surrounding_cells(self.current_tile_coords)
			
			## Iterate through potential directions
			surrounding.shuffle() ## FIXME HACK: random -- ideally could order the items based on priority
			while not coords:
				if not surrounding.is_empty():
					var _try: Vector2i = surrounding.pop_back()
					
					_try.x *= distance
					_try.y *= distance
					
					## Confirm the cell exists
					var exists: bool = TileInteractor.cell_exists(_try, self.tile_map)
					if exists:
						## Found a tile to move to.
						
						## Check it isn't occupied:
						for actor in actors:
							if _try == actor.current_tile_coords: ## BUG: two actors can plan to move to the same tile next turn if that tile is presently unoccupied
								## Occupado
								continue
						coords = _try
						break
					else:
						## Didn't find a tile to move to.
						continue
				else:
					## Couldn't find a tile to move to -- don't move the actor.
					coords = self.current_tile_coords
		
		## Set the destination coords
		action.destination_coords = coords
		
		## Choose a facing direction
		## FIXME HACK: Random, this should look towards the destination
		facing_direction = Facing.Cardinal.values().pick_random()
		
	## Set this actor's facing direction
	## The action determines the facing direction
	## You want to face the direction that your actioning towards
	## This can mean different things depending on the action.
	set_facing(facing_direction)
