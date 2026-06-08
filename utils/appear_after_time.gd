extends CanvasItem

@export var reveal_wait_time: float = 2.0

func _enter_tree() -> void:
	visibility_changed.connect(_on_visibility_changed)
	hide()

var t: Tween
func _on_visibility_changed() -> void:
	if not visible:
		modulate = Color.TRANSPARENT
		return
	if t:
		t.kill()
	t = create_tween()
	t.tween_interval(reveal_wait_time)
	t.tween_property(self, "modulate", Color.WHITE, Juice.FAST)
