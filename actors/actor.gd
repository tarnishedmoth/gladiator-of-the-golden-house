class_name Actor extends Node2D

var current_tile_coords: Vector2i
var tile_map: TileMapLayer
var director: Director

func setup(director: Director, tilemap: TileMapLayer) -> void:
	self.director = director
	self.tile_map = tilemap

func move_to_tile(coords: Vector2i, map: TileMapLayer = tile_map) -> void:
	if not tile_map: return
	
	current_tile_coords = coords
	var move_tween := create_tween()
	move_tween.set_ease(Tween.EASE_OUT)
	move_tween.tween_property(self, ^"global_position", get_global_position_at(map, coords), 1.0)

static func get_global_position_at(map: TileMapLayer, coords: Vector2i) -> Vector2:
	return map.to_global(map.map_to_local(coords))
	
