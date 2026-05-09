class_name Targeting extends Node

const COLORS = {
	RED = Color("ff0000ff"),
	PINK = Color("bf5065ff"),
	WHITE = Color("ffffffff"),
	BLUE = Color("7a5cffff"),
	YELLOW = Color("dec000ff"),
	GREY = Color("555555ff")
}

const TARGET_INDICATOR_VISUAL = preload("uid://bw78572gtph87")
var targ_scene: PackedScene = TARGET_INDICATOR_VISUAL
var tilemap: TileMapLayer

func setup(tilemap_ref: TileMapLayer):
	tilemap = tilemap_ref

## Alpha value is overridden in the script [TargetIndicatorVisual] (target_indicator.gd)
func highlight_target(coords: Vector2i, color: Color) -> void:
	if tilemap.get_cell_tile_data(coords): ## Valid tile
		var target_highlight: TargetIndicatorVisual = targ_scene.instantiate()
		
		target_highlight.set_color(color)
		add_child(target_highlight)
		target_highlight.global_position = tilemap.to_global(tilemap.map_to_local(coords))
		target_highlight.add_to_group("target_highlights")

func highlight_targets(targets: Array[Vector2i], color: Color):
	for entry in targets:
		highlight_target(entry, color)

func translate_and_highlight_targets(pos: Vector2i, facing: int, pattern: Array[Vector2i], color: Color):
	highlight_targets(Facing.get_target_cells(pos,facing,pattern), color) # take in the unit pos, unit facing, and target pattern

func highlight_aoe(coords: Vector2i, color: Color) -> void:
	if tilemap.get_cell_tile_data(coords): ## Valid tile
		var aoe_target_highlight: TargetIndicatorVisual = targ_scene.instantiate()
		
		aoe_target_highlight.set_color(color)
		add_child(aoe_target_highlight)
		aoe_target_highlight.global_position = tilemap.to_global(tilemap.map_to_local(coords))
		aoe_target_highlight.add_to_group("target_highlights")
	
func highlight_aoe_spots(targets: Array[Vector2i], color: Color):
	for entry in targets:
		highlight_aoe(entry, color)

func translate_and_highlight_aoe_spots(pos: Vector2i, facing: int, pattern: Array[Vector2i], color: Color):
	highlight_aoe_spots(Facing.get_target_cells(pos,facing,pattern), color) #take in the selected target spot, unit facing, and ae_pattern


func clear_target_highlights():
	for node: TargetIndicatorVisual in get_tree().get_nodes_in_group("target_highlights"):
		node.despawn()
