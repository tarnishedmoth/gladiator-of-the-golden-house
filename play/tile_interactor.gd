class_name TileInteractor extends Node2D

const VERBOSE: bool = true

signal tile_changed(new_coords: Vector2i)

var tilemap: TileMapLayer
var current_coords: Vector2i ## Last polled coordinates. Updates every frame, before [signal tile_changed].
var last_coords: Vector2i ## Previous frame's coordinates. Updates every frame, after [signal tile_changed].

func set_tilemap(tile_map: TileMapLayer) -> void:
	tilemap = tile_map
	
## Returns the coordinates if a valid tile, otherwise returns null.
func get_tile_coords_under_interactor() -> Variant:
	var coords: Vector2i = tilemap.local_to_map(tilemap.to_local(global_position))
	var data: TileData = tilemap.get_cell_tile_data(coords)
	if data:
		return coords
	else:
		return null
	
func get_current_tile_coords() -> Vector2i:
	return current_coords
	
func get_current_tile_data() -> TileData:
	if tilemap:
		return tilemap.get_cell_tile_data(current_coords)
	else:
		return null

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if tilemap:
		## Check if we're hovering over any tile
		var coords = get_tile_coords_under_interactor()
		if coords == null:
			## No tile under cursor
			pass
		else:
			#var data: TileData = tilemap.get_cell_tile_data(coords)
			if not last_coords == coords:
				## New tile
				current_coords = coords
				tile_changed.emit(current_coords)
				
				if VERBOSE:
					print("%s at %s" % [tilemap.get_cell_tile_data(coords), current_coords])
				last_coords = coords
