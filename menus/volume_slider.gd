@tool
extends HBoxContainer

@export var title: String:
	set(v):
		title = v
		if label:
			label.text = title

@export var bus_name: StringName:
	set(v):
		bus_name = v
		if Engine.is_editor_hint():
			_ready()

var audio_bus_idx: int

@onready var label: Label = $Label
@onready var h_slider: HSlider = $HSlider
@onready var units: Label = $Units

func _ready() -> void:
	if not Engine.is_editor_hint():
		if not bus_name:
			push_error("Volume slider needs a bus name. Freeing")
			queue_free()
			return
	
	audio_bus_idx = AudioServer.get_bus_index(bus_name)
	if title:
		label.text = title
	
	populate_values()


func populate_values() -> void:
	if audio_bus_idx == -1:
		return
	
	h_slider.set_value_no_signal(roundi(AudioServer.get_bus_volume_linear(audio_bus_idx) * 100))
	_set_units_text()

func _on_h_slider_value_changed(value: float) -> void:
	if Engine.is_editor_hint():
		return
	
	_set_units_text()
	AudioServer.set_bus_volume_linear(audio_bus_idx, h_slider.value / 100.0)

func _set_units_text() -> void:
	var pct: int = roundi(h_slider.value)
	units.text = str(pct) + "%"
