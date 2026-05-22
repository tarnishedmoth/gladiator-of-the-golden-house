class_name SaveSlotsContainer extends PanelContainer

signal selected(slot:int)

var display_summaries: Array[String]

@export var slots: Array[Button]
@export var disable_empty: bool = true

@onready var display_summary: Label = %DisplaySummary

func _ready() -> void:
	display_summary.modulate = Color.TRANSPARENT
	display_summaries.resize(slots.size())
	repopulate_buttons()

func repopulate_buttons() -> void:
	for i in slots.size():
		var metadata: SaveLoad.Metadata = SaveLoad.load_metadata_from_disk(SaveLoad.get_filepath_for_slot(i))
		if metadata != null:
			display_summaries[i] = metadata.display_summary
			slots[i].disabled = false
		else:
			display_summaries[i] = "Empty save slot"
			slots[i].disabled = true if disable_empty else false

func _on_slot_button_pressed(slot: int) -> void:
	selected.emit(slot)


func _on_slot_button_focus_entered(slot: int) -> void:
	display_summary.text = display_summaries[slot]
	display_summary.modulate = Color.WHITE


func _on_slot_button_focus_exited(_slot: int) -> void:
	display_summary.modulate = Color.TRANSPARENT


func _on_slot_button_mouse_entered(slot: int) -> void:
	display_summary.text = display_summaries[slot]
	display_summary.modulate = Color.WHITE


func _on_slot_button_mouse_exited(_slot: int) -> void:
	display_summary.modulate = Color.TRANSPARENT
