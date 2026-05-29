extends PanelContainer

signal exited

@onready var main_options: VBoxContainer = %MainOptions
@onready var help_options: VBoxContainer = %HelpOptions
@onready var stuck_game_options: VBoxContainer = %StuckGameOptions

@onready var confirm_dialog: ConfirmDialog = %ConfirmPage

func _enter_tree() -> void:
	hide()

func close_options() -> void:
	hide()
	main_options.show()
	exited.emit()


func _on_help_button_pressed() -> void:
	help_options.show()
	
func _on_stuck_game_button_pressed() -> void:
	stuck_game_options.show()

func _on_back_to_options_pressed() -> void:
	main_options.show()


## Recovery methods

func _on_check_objectives_button_pressed() -> void:
	if Level.instance:
		Level.get_instance().check_objectives()

func _on_end_turn_button_pressed() -> void:
	if Level.instance:
		Level.get_current_director().end_turn()

func _on_go_back_level_button_pressed() -> void:
	if not PlayerData.this:
		return
	
	confirm_dialog.ask_confirm(
		"This will reduce your level by one and load the appropriate level to play. Your save will not be affected until next level completion."
		)
		
	await confirm_dialog.exited
	if confirm_dialog.last_result:
		PlayerData.this.current_level -= 1
		Main.load_latest_level()
		close_options()
		get_tree().paused = false
	else:
		help_options.show()

func _on_skip_level_button_pressed() -> void:
	if not PlayerData.this:
		return
	
	confirm_dialog.ask_confirm(
		"This will increase your level by one and load the next level to play. Your save will be overwritten."
		)
		
	await confirm_dialog.exited
	if confirm_dialog.last_result:
		Main.register_level_progressed()
		Main.load_latest_level()
		close_options()
		get_tree().paused = false
	else:
		help_options.show()


func _on_restart_level_button_pressed() -> void:
	if not PlayerData.this:
		return
		
	confirm_dialog.ask_confirm(
		"This will reload the current level."
		)
		
	await confirm_dialog.exited
	if confirm_dialog.last_result:
		Main.load_latest_level()
		close_options()
		get_tree().paused = false
	else:
		help_options.show()


func _on_clear_character_datat_button_pressed() -> void:
	if not PlayerData.this:
		return
		
	confirm_dialog.ask_confirm(
		"This will clear your character's data such as their health.
		Your save progress will not be affected.
		You can choose to restart the level after doing this to experience the changes."
		)
		
	await confirm_dialog.exited
	if confirm_dialog.last_result:
		PlayerData.wipe_actor_data()
	help_options.show()


func _on_exit_options_button_pressed() -> void:
	close_options()
