extends Control

@export var main_menu_scene: PackedScene
@export var next_level_scene: PackedScene

func _on_continue_pressed() -> void:
	Main.change_scene(next_level_scene)

func _on_main_menu_pressed() -> void:
	Main.change_scene(main_menu_scene)
