extends Control

func _on_main_menu_pressed() -> void:
	Main.go_to_main_menu()

func _on_retry_pressed() -> void:
	Main.reload_current_scene()
