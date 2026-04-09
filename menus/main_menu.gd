extends Control

enum SlotScreenStates {
	LOADING,
	SAVING
}

const META_STARTING_CLASS: StringName = &"scene"
var selected_starting_class: String: ## UID
	set(v):
		confirm_class_button.disabled = false if v else true
		selected_starting_class = v
		
var slot_screen_state: SlotScreenStates

@onready var main_menu_tab: VBoxContainer = %MainMenuTab
@onready var new_game_tab: MarginContainer = %NewGameTab

@onready var select_save_slot_tab: MarginContainer = %SelectSaveSlotTab
@onready var save_slots_container: SaveSlotsContainer = %SaveSlotsContainer

@onready var continue_button: Button = %ContinueButton
@onready var new_game_button: Button = %NewGameButton
@onready var options_button: Button = %OptionsButton
@onready var quit_button: Button = %QuitButton

@onready var classes_grid_container: HFlowContainer = %ClassesGridContainer
@onready var chosen_name_line_edit: LineEdit = %ChosenNameLineEdit
@onready var confirm_class_button: Button = %ConfirmClassButton

func _ready() -> void:
	main_menu_tab.show()
	continue_button.disabled = SaveLoad.get_save_slots().is_empty()

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
	slot_screen_state = SlotScreenStates.LOADING
	save_slots_container.disable_empty = true
	save_slots_container.repopulate_buttons()
	select_save_slot_tab.show()

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

## Configured a new playthrough
func _on_confirm_button_pressed() -> void:
	slot_screen_state = SlotScreenStates.SAVING
	save_slots_container.disable_empty = false
	save_slots_container.repopulate_buttons()
	select_save_slot_tab.show()


func _on_save_slot_selected(slot: int) -> void:
	SaveLoad.current_save_slot = slot
	
	match slot_screen_state:
		SlotScreenStates.LOADING:
			SaveLoad.load_current_save_slot()
			Main.continue_level.call_deferred()
		SlotScreenStates.SAVING:
			## New game
			PlayerData.new_playthrough(chosen_name_line_edit.text, selected_starting_class)
			#SaveLoad.save_game()
			Main.play_level.call_deferred(0)
