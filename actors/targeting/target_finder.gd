class_name Targeting extends Node

const TARGET_INDICATOR = preload("uid://bw78572gtph87")
var targ_scene: PackedScene = TARGET_INDICATOR
var tilemap = TileMapLayer

func setup(tilemap_ref: TileMapLayer):
	tilemap = tilemap_ref

func highlight_targets(pos: Vector2i, facing: int, pattern: Array):
	var targets = Facing.get_target_cells(pos,facing,pattern) # take in the unit pos, unit facing, and target pattern
	for entry in targets:
		var target_highlight = targ_scene.instantiate()
		target_highlight.hide()
		add_child(target_highlight)
		target_highlight.global_position = tilemap.to_global(tilemap.map_to_local(entry))
		target_highlight.add_to_group("target_highlights")
		target_highlight.show()

func highlight_aoe_spots(pos: Vector2i, facing: int, pattern: Array):
	var ae_targets = Facing.get_target_cells(pos,facing,pattern) #take in the selected target spot, unit facing, and ae_pattern
	for entry in ae_targets:
		var aoe_target_highlight = targ_scene.instantiate()
		aoe_target_highlight.hide()
		add_child(aoe_target_highlight)
		aoe_target_highlight.modulate(Color.PURPLE)
		aoe_target_highlight.global_position = tilemap.to_global(tilemap.map_to_local(entry))
		aoe_target_highlight.add_to_group("target_highlights")
		aoe_target_highlight.show()

	
func clear_target_highlights():
	for node in get_tree().get_nodes_in_group("target_highlights"):
		node.queue_free()
