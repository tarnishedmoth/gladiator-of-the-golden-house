class_name Targeting extends Node

const TARGET_INDICATOR = preload("uid://bw78572gtph87")
var targ_scene: PackedScene = TARGET_INDICATOR
var tilemap = TileMapLayer

func setup(tilemap_ref: TileMapLayer):
	tilemap = tilemap_ref

func highlight_target(pos: Vector2i) -> void:
	var target_highlight = targ_scene.instantiate()
	target_highlight.hide()
	add_child(target_highlight)
	target_highlight.global_position = tilemap.to_global(tilemap.map_to_local(pos))
	target_highlight.add_to_group("target_highlights")
	target_highlight.show()

func highlight_targets(targets: Array[Vector2i]):
	for entry in targets:
		highlight_target(entry)

func translate_and_highlight_targets(pos: Vector2i, facing: int, pattern: Array[Vector2i]):
	highlight_targets(Facing.get_target_cells(pos,facing,pattern)) # take in the unit pos, unit facing, and target pattern

func highlight_aoe(pos: Vector2i) -> void:
	var aoe_target_highlight = targ_scene.instantiate()
	aoe_target_highlight.hide()
	add_child(aoe_target_highlight)
	aoe_target_highlight.modulate(Color.PURPLE)
	aoe_target_highlight.global_position = tilemap.to_global(tilemap.map_to_local(pos))
	aoe_target_highlight.add_to_group("target_highlights")
	aoe_target_highlight.show()
	
func highlight_aoe_spots(targets: Array[Vector2i]):
	for entry in targets:
		highlight_aoe(entry)

func translate_and_highlight_aoe_spots(pos: Vector2i, facing: int, pattern: Array[Vector2i]):
	highlight_aoe_spots(Facing.get_target_cells(pos,facing,pattern)) #take in the selected target spot, unit facing, and ae_pattern


func clear_target_highlights():
	for node in get_tree().get_nodes_in_group("target_highlights"):
		node.queue_free()
