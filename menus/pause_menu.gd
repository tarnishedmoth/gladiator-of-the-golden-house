extends PanelContainer

func _enter_tree() -> void:
	hide()

func _on_resume_button_pressed() -> void:
	Level.get_instance().pause_game(false)
	hide()

func _on_options_button_pressed() -> void:
	Main.sfx_blip() ## sfx
	Main.show_options_panel()


func _on_main_menu_button_pressed() -> void:
	Main.sfx_blip() ## sfx
	Main.go_to_main_menu()
