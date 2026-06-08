extends CanvasItem

@export var color_a: Color = Color.WHITE
@export var color_b: Color = Color.WEB_GRAY

@export var cycle_duration: float = 0.8:
	get:
		return maxf(0.05, cycle_duration)
		
func _enter_tree() -> void:
	self_modulate = color_a

func _ready() -> void:
	var t: Tween = create_tween()
	t.set_trans(Tween.TRANS_SINE)
	t.tween_property(self, ^"self_modulate", color_a, cycle_duration/2.0)
	t.tween_property(self, ^"self_modulate", color_b, cycle_duration/2.0)
	t.set_loops()
