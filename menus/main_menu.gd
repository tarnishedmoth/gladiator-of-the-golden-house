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
		
const META_CHARACTER_ART: StringName = &"art"
var selected_character_art: String: ## UID
	set(v):
		confirm_art_button.disabled = false if v else true
		selected_character_art = v
		
var slot_screen_state: SlotScreenStates

@onready var main_menu_tab: VBoxContainer = %MainMenuTab
@onready var select_class_tab: MarginContainer = %SelectClassTab
@onready var select_art_tab: MarginContainer = %SelectArtTab

@onready var select_save_slot_tab: MarginContainer = %SelectSaveSlotTab
@onready var save_slots_container: SaveSlotsContainer = %SaveSlotsContainer

@onready var continue_button: Button = %ContinueButton
@onready var new_game_button: Button = %NewGameButton
@onready var options_button: Button = %OptionsButton
@onready var quit_button: Button = %QuitButton

@onready var classes_grid_container: HFlowContainer = %ClassesGridContainer
@onready var chosen_name_line_edit: LineEdit = %ChosenNameLineEdit
@onready var confirm_class_button: Button = %ConfirmClassButton

@onready var art_grid_container: HFlowContainer = %ArtGridContainer
@onready var confirm_art_button: Button = %ConfirmArtButton

func _ready() -> void:
	main_menu_tab.show()
	continue_button.disabled = SaveLoad.get_save_slots().is_empty()
	
	var start_music = create_tween()
	start_music.tween_interval(1.8) ## Wait a hot moment
	start_music.tween_callback(Main.play_music_menu_loop.bind(true))

func populate_starting_classes() -> void:
	for child in classes_grid_container.get_children(): child.queue_free()
	for iter in PlayerData.STARTING_CLASSES.size():
		var button = Button.new()
		button.toggle_mode = true
		button.theme_type_variation = &"BigButton"
		
		var class_display_name: String = PlayerData.STARTING_CLASSES.keys()[iter]
		class_display_name = class_display_name.capitalize() ## dang this method is cool
		
		button.text = class_display_name
		button.set_meta(META_STARTING_CLASS, PlayerData.STARTING_CLASSES.values()[iter])
		
		button.pressed.connect(_on_class_select_button_pressed.bind(button))
		classes_grid_container.add_child(button)
	
	for child in art_grid_container.get_children(): child.queue_free()
	for iter in PlayerData.CHARACTER_SCENES.size():
		var button = Button.new()
		button.toggle_mode = true
		#button.text = PlayerData.CHARACTER_SCENES.keys()[iter].capitalize()
		## Not showing text because you can't configure a button text's vertical position.
		## There is a hacky workaround by providing a transparent texture to the icon property
		## But frankly the names aren't important for this UI
		
		var art_uid: String = PlayerData.CHARACTER_SCENES.values()[iter]
		button.set_meta(META_CHARACTER_ART, art_uid)
		button.pressed.connect(_on_art_select_button_pressed.bind(button))
		
		## We are going to assume all player character scenes are the same size
		## So let's hack those sprites into this Control layout
		var padding := Vector2(16, 16)
		var art_size := Vector2(64, 64)
		button.custom_minimum_size = art_size + padding
		
		var art_scene: PackedScene = load(art_uid)
		var art_instance: Node2D = art_scene.instantiate()
		button.add_child(art_instance)
		
		art_grid_container.add_child(button)
		art_instance.position = button.size / 2.0


func _on_class_select_button_pressed(button: Button) -> void:
	selected_starting_class = button.get_meta(
		META_STARTING_CLASS,
		PlayerData.STARTING_CLASSES.values().front()
		)
	
	for child: Button in classes_grid_container.get_children():
		child.set_pressed_no_signal(child == button)

func _on_art_select_button_pressed(button: Button) -> void:
	selected_character_art = button.get_meta(
		META_CHARACTER_ART,
		PlayerData.CHARACTER_SCENES.values().front()
		)
	
	for child: Button in art_grid_container.get_children():
		child.set_pressed_no_signal(child == button)


func _on_continue_button_pressed() -> void:
	slot_screen_state = SlotScreenStates.LOADING
	save_slots_container.disable_empty = true
	save_slots_container.repopulate_buttons()
	select_save_slot_tab.show()

func _on_new_game_button_pressed() -> void:
	populate_starting_classes()
	select_class_tab.show()


func _on_options_button_pressed() -> void:
	Main.show_options_panel()


func _on_quit_button_pressed() -> void:
	## TODO
	pass # Replace with function body.


func _on_go_back_button_pressed() -> void:
	if select_art_tab.visible:
		## Go back to class tab
		select_class_tab.show()
	else:
		## Return to main menu
		selected_starting_class = ""
		selected_character_art = ""
		main_menu_tab.show()

## Picked a class, now to pick character art
func _on_confirm_class_button_pressed() -> void:
	select_art_tab.show()

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
			Main.play_music_menu_loop(false) ## First cutscene in a new playthrough will mute the music otherwise
		
		SlotScreenStates.SAVING:
			## New game
			PlayerData.new_playthrough(chosen_name_line_edit.text, selected_starting_class, selected_character_art)
			#SaveLoad.save_game()
			Main.play_level.call_deferred(0)
