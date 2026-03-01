extends Control

@export var main_menu_scene: PackedScene

func _on_main_menu_pressed() -> void:
	Main.change_scene(main_menu_scene)

func _on_retry_pressed() -> void:
	Main.reload_current_scene()
