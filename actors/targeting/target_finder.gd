class_name Targeting extends Node

static var VERBOSE: bool = false
static func p(args) -> void:
	if VERBOSE: print_rich("[color=white][bgcolor=grey]Targeting: ", args)

const COLORS = {
	RED = Color("da0000ff"),
	PINK = Color("cd367aff"),
	WHITE = Color("ffffffff"),
	BLUE = Color("4895ffff"),
	GREEN = Color(0.132, 0.823, 0.757, 1.0),
	YELLOW = Color("ffc944ff"),
	GREY = Color("555555ff")
}

const GROUP_NAME: StringName = &"target_highlights"

const TARGET_INDICATOR_VISUAL = preload("uid://bw78572gtph87")
const TARGET_EXECUTION_VISUAL = preload("uid://d01as0qnw5yn1")
var targ_scene: PackedScene = TARGET_INDICATOR_VISUAL
var targ_executing_scene: PackedScene = TARGET_EXECUTION_VISUAL
var tilemap: TileMapLayer

var highlights: Dictionary[StringName, Array] = {} ## Actor, Array of nodes (highlights).
func get_uid(node: Node) -> StringName:
	return node.get_parent().name + "-" + node.name

func setup(tilemap_ref: TileMapLayer):
	tilemap = tilemap_ref

## Alpha value is overridden in the script [TargetIndicatorVisual] (target_indicator.gd)
func highlight_target(coords: Vector2i, color: Color, source_owner: Actor) -> void:
	if tilemap.get_cell_tile_data(coords): ## Valid tile
		var target_highlight: TargetIndicatorVisual = targ_scene.instantiate()
		
		target_highlight.set_color(color)
		target_highlight.scale *= 0.6
		target_highlight.global_position = tilemap.to_global(tilemap.map_to_local(coords))
		add_child(target_highlight)
		
		target_highlight.add_to_group(GROUP_NAME)
		var uid: StringName = get_uid(source_owner)
		p("Created targets for %s" % uid)
		var list: Array = highlights.get_or_add(uid, [])
		list.append(target_highlight)

func highlight_targets(targets: Array[Vector2i], color: Color, source_owner: Actor):
	for entry in targets:
		highlight_target(entry, color, source_owner)

## This method has turned into an alias for the regular [method highlight_target] method.
func highlight_aoe(coords: Vector2i, color: Color, source_owner: Actor) -> void:
	highlight_target(coords, color, source_owner)
	
func highlight_aoe_spots(targets: Array[Vector2i], color: Color, source_owner: Actor):
	for entry in targets:
		highlight_aoe(entry, color, source_owner)

## Clear all [TargetIndicatorVisual] in the scene tree group [member GROUP_NAME].
func clear_target_highlights(source_owner: Actor):
	#for node: TargetIndicatorVisual in get_tree().get_nodes_in_group(GROUP_NAME):
		#node.despawn()
	if not source_owner:
		push_error("Null actor provided. Ignoring call.")
		return
	var uid: StringName = get_uid(source_owner)
	var list = highlights.get(uid, null)
	
	if list:
		p("Clearing targets for %s" % uid)
		for node: TargetIndicatorVisual in list:
			node.despawn()
		list.clear()

func clear_all_highlights():
	p("Clearing all highlights.")
	for list: Array in highlights.values():
		for node: TargetIndicatorVisual in list:
			node.despawn()
	highlights.clear()


func highlight_momentary(targets: Array[Vector2i], color: Color, show_fill: bool = false, time: float = Juice.SMOOTH) -> void:
	for entry in targets:
		if tilemap.get_cell_tile_data(entry): ## Valid tile
			var target_highlight: TargetIndicatorVisual = targ_executing_scene.instantiate()
			
			target_highlight.animate_on_enter = false ## do our own animation here
			target_highlight.show_fill = show_fill
			target_highlight.modulate = color #Color(color, 0.75)
			target_highlight.scale *= 0.94
			target_highlight.global_position = tilemap.to_global(tilemap.map_to_local(entry))
			add_child(target_highlight)
			
			var t: Tween = target_highlight.create_tween()
			t.set_ease(Tween.EASE_IN)
			t.tween_property(target_highlight, ^"modulate", Color(color, 0.0), time)
			t.parallel()
			t.tween_property(target_highlight, ^"scale", Vector2(1.0, 1.0), Juice.BLITZ).set_trans(Tween.TRANS_QUAD)
			t.tween_callback(target_highlight.queue_free)
