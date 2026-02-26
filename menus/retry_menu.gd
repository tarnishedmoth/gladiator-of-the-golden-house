extends Control

@export var main_menu_scene: PackedScene

func _on_main_menu_pressed() -> void:
	get_tree().change_scene_to_packed(main_menu_scene)

func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()
