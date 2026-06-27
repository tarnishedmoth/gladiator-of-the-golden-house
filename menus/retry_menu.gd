extends Control

func _on_main_menu_pressed() -> void:
	if Level.get_instance().stop_music_on_exit_to_menu:
		Main.stop_music()
	Main.go_to_main_menu()

func _on_retry_pressed() -> void:
	Main.reload_current_scene()
