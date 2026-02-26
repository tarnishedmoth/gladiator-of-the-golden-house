extends Control

@export var main_menu_scene: PackedScene
@export var next_level_scene: PackedScene

func _on_continue_pressed() -> void:
	get_tree().change_scene_to_packed(next_level_scene)
	pass

func _on_main_menu_pressed() -> void:
	get_tree().change_scene_to_packed(main_menu_scene)
	
