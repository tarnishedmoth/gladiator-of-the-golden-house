extends Control

func _on_continue_pressed() -> void:
	if Level.get_instance().stop_music_on_exit_to_next_level:
		Main.play_music_menu_loop(false)
		Main.play_sherman(false)
		Main.play_vaillancourt(false)
	Main.sfx_blip()
	Main.load_latest_level()

func _on_main_menu_pressed() -> void:
	if Level.get_instance().stop_music_on_exit_to_menu:
		Main.play_music_menu_loop(false)
		Main.play_sherman(false)
		Main.play_vaillancourt(false)
	Main.sfx_blip()
	Main.go_to_main_menu()
