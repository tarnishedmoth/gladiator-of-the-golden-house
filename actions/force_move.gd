class_name ActionForceMove extends Action

## TESTING required
## Try to move the target actor to the target tile.
## If the tile is occupied, or is beyond the edge of the tilemap,
## move as far as possible in that direction,
## and optionally deal damage and apply a status.

@export var is_obstructable_along_path: bool = true ## If false, behaves like being thrown over the air to that tile.

var actor_to_move: Actor

## On transition to this state
func enter(_from: ResourceState = null) -> void:
	await do()
	exit()

## TESTING required
func do() -> void:
	if not actor_to_move:
		push_error("Actor is invalid")
		return
	var tile_map: TileMapLayer = actor_to_move.tile_map
	if not tile_map:
		push_error("Tilemap is invalid")
		return
	if (_target == null) or (not _target in tile_map.get_used_cells()):
		push_error("Target coord is invalid")
		return
	
	var start_coord: Vector2i = actor_to_move.current_tile_coords
	var end_coord: Vector2i = _target
	
	if is_obstructable_along_path:
		var surrounding_cells := tile_map.get_surrounding_cells(start_coord)
		if not end_coord in surrounding_cells:
			## check along that path for tiles passed over.
			var tiles_passed_over: Array[Vector2i] = Cube.get_inline_tiles(start_coord, end_coord)
			if debug: p("Checking path between %s and %s...\nTiles:\n%s" % [start_coord, end_coord, tiles_passed_over])
			
			var last_valid_tile: Vector2i = start_coord
			for tile in tiles_passed_over:
				if Level.get_actor_at(tile):
					if debug: p("Obstructed at %s." % tile)
					break
				last_valid_tile = tile
			end_coord = last_valid_tile
	
	if Level.get_actor_at(end_coord):
		if debug: p("End tile %s is obstructed--not moving." % end_coord)
		on_hit_obstruction()
	else:
		if debug: p("Moving %s to %s!" % [actor_to_move, end_coord])
		actor_to_move.move_to_tile(end_coord)
		await actor_to_move.animation_finished
		
		if end_coord != _target:
			on_hit_obstruction()


func on_hit_obstruction() -> void:
	p("on_hit_obstruction")
	pass
