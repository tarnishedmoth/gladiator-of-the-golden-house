class_name TileWatcher extends Node2D

const GROUP_NAME: StringName = &"TileWatchers"

@export var exclude_source: bool = true
@export var exclude_friendly: bool = true

@export var aoe_pattern: Array[Vector2i] = [Vector2i(0,0)]
func get_aoe() -> Array[Vector2i]: return Facing.get_target_cells(current_tile_coords, facing, aoe_pattern)

@export var facing: Facing.Cardinal = Facing.Cardinal.NORTH

var current_tile_coords: Vector2i
var tile_map: TileMapLayer:
	get:
		if not tile_map:
			tile_map = Level.get_base_tile_map_layer()
		if not tile_map:
			return null
		return tile_map
		
var source: Actor

func setup(coords: Vector2i, source_actor: Actor) -> void:
	current_tile_coords = coords
	source = source_actor
	snap_to_tile()
	add_to_group(GROUP_NAME)
	
func snap_to_tile() -> void:
	assert(tile_map.get_cell_tile_data(current_tile_coords))
	global_position = tile_map.to_global(tile_map.map_to_local(current_tile_coords))


func on_actor_moved(actor: Actor) -> bool:
	if exclude_friendly:
		if actor.director == source.director:
			return false
	
	if exclude_source:
		if actor == source:
			return false
			
	var aoe := get_aoe()
	if actor.current_tile_coords in aoe:
		await hook(actor)
		return true
	return false

func hook(triggering: Actor) -> bool:
	
	## TODO
	print("Tile watcher at %s triggered by %s" % [current_tile_coords, triggering])
	
	on_after_hook()
	return true

func on_after_hook() -> void:
	queue_free()
