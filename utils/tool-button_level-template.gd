@tool
extends Node2D

## Just adds the player instance placeholder and an AI director to the scene for you

const PLAYER_NODE: PackedScene = preload("uid://c5wwjkucrew5h")
const AI_NODE = preload("uid://dwys5mwbuw85s")

@export_tool_button("Create Directors") var do = _do

func _do():
	if not get_children().is_empty():
		push_warning("Already has directors... watch for duplicates.")
	
	var ai_instance: AIDirector = AIDirector.new()
	ai_instance.name = "AIDirector"
	add_child(ai_instance, true, Node.INTERNAL_MODE_DISABLED)
	ai_instance.owner = get_tree().edited_scene_root
	
	var player_instance: PlayerInsertPlaceholder = PLAYER_NODE.instantiate()
	add_child(player_instance, true, Node.INTERNAL_MODE_DISABLED)
	player_instance.owner = get_tree().edited_scene_root
