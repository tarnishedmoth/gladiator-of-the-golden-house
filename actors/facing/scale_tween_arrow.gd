func _ready() -> void:
	# pivot at the base so it grows "forward" instead of from center
	pivot_offset = Vector2(size.x * 0.5, size.y)  # Control nodes
	# for Node2D/Sprite2D, set the texture's offset or position the origin at the base instead

	scale = Vector2(1.0, 0.0)
	var tween := create_tween().set_loops()
	tween.tween_property(self, "scale:y", 1.0, 1.3)
	tween.tween_property(self, "scale:y", 0.0, 1.3)
