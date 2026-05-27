extends Control

func _on_continue_pressed() -> void:
	Main.load_latest_level()

func _on_main_menu_pressed() -> void:
	Main.go_to_main_menu()
