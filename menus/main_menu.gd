extends Control

const META_STARTING_CLASS: StringName = &"scene"
var selected_starting_class: String: ## UID
	set(v):
		confirm_class_button.disabled = false if v else true
		selected_starting_class = v

@onready var main_menu_tab: VBoxContainer = %MainMenuTab
@onready var new_game_tab: MarginContainer = %NewGameTab

@onready var continue_button: Button = %ContinueButton
@onready var new_game_button: Button = %NewGameButton
@onready var options_button: Button = %OptionsButton
@onready var quit_button: Button = %QuitButton

@onready var classes_grid_container: HFlowContainer = %ClassesGridContainer
@onready var chosen_name_line_edit: LineEdit = %ChosenNameLineEdit
@onready var confirm_class_button: Button = %ConfirmClassButton

func _ready() -> void:
	main_menu_tab.show()

func populate_starting_classes() -> void:
	for child in classes_grid_container.get_children(): child.queue_free()
	for iter in PlayerData.STARTING_CLASSES.size():
		var button = Button.new()
		button.text = PlayerData.STARTING_CLASSES.keys()[iter]
		button.set_meta(META_STARTING_CLASS, PlayerData.STARTING_CLASSES.values()[iter])
		button.pressed.connect(_on_class_select_button_pressed.bind(button))
		classes_grid_container.add_child(button)

func _on_class_select_button_pressed(button: Button) -> void:
	selected_starting_class = button.get_meta(META_STARTING_CLASS)

func _on_continue_button_pressed() -> void:
	## TODO
	Main.continue_level()

func _on_new_game_button_pressed() -> void:
	populate_starting_classes()
	new_game_tab.show()


func _on_options_button_pressed() -> void:
	## TODO
	pass # Replace with function body.


func _on_quit_button_pressed() -> void:
	## TODO
	pass # Replace with function body.


func _on_go_back_button_pressed() -> void:
	selected_starting_class = ""
	main_menu_tab.show()

func _on_confirm_button_pressed() -> void:
	PlayerData.new_playthrough(chosen_name_line_edit.text, selected_starting_class)
	Main.play_level(0)
