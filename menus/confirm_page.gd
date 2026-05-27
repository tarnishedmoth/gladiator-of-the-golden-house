class_name ConfirmDialog extends VBoxContainer

signal exited(result: bool)

var last_result: bool

@onready var confirm_details: Label = %ConfirmDetails

func ask_confirm(details: String = "") -> void:
	confirm_details.text = details
	show()

func _on_cancel_button_pressed() -> void:
	last_result = false
	exited.emit(false)

func _on_confirm_button_pressed() -> void:
	last_result = true
	exited.emit(true)
