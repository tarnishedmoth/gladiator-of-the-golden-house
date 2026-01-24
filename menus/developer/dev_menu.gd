class_name DeveloperMainMenu extends Control

@export var selectable_levels: Array[PackedScene]

@onready var select_dropdown: OptionButton = %SelectDropdown
@onready var main: Main = get_parent()

@onready var bg: ColorRect = %BG
@onready var contents: VBoxContainer = %Contents

func _ready() -> void:
	var id:int = 1 # 0 is reserved for divider.
	for level in selectable_levels:
		if level is PackedScene:
			# Valid array entry
			select_dropdown.add_item(level.resource_path.trim_prefix("res://"), id) # Display text
			select_dropdown.set_item_metadata(id, level.resource_path) # Filepath
			id += 1
			
	Juice.fade_in(contents, Juice.PATIENT, Color.TRANSPARENT)


func _on_launch_button_pressed() -> void:
	var resource:PackedScene = load(select_dropdown.get_item_metadata(select_dropdown.selected))
	
	# Visual effect
	var exit:Tween = Juice.fade_out(bg, Juice.SNAPPY, Color.BLACK)
	await exit.finished
	
	# Action
	main.change_scene(resource)
