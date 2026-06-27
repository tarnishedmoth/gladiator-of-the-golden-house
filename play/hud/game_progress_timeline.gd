class_name GameProgressTimeline extends Control

@onready var h_slider: HSlider = $HSlider
@onready var label: Label = $Label

func _enter_tree() -> void:
	modulate = Color.TRANSPARENT

func _ready() -> void:
	update_value_from_player_data()
	
func update_value_from_player_data() -> void:
	if PlayerData.this:
		set_value(
			PlayerData.this.get_current_level(),
			Main.instance.levels.size()
		)

func set_value(current: int, max_v: int) -> void:
	h_slider.max_value = max_v
	h_slider.tick_count = max_v + 1
	h_slider.value = current
	flash()
	
func set_label(text: String) -> void:
	label.text = text

func flash() -> void:
	Juice.flash(self, Juice.PulsePresets.Three)

func reveal() -> void:
	var v = create_tween()
	v.tween_property(self, ^"modulate", Color.WHITE, Juice.SMOOTH)
