extends Node2D

func _ready() -> void:
	var tween = create_tween().set_loops()
	tween.tween_property(self, "scale", Vector2(0.95,0.95),1.0)
	tween.tween_property(self, "scale", Vector2(1.1,1.1),1.0)
