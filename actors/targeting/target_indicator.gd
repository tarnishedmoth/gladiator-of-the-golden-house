class_name TargetIndicatorVisual extends Node2D

const ALPHA_VALUE = 114

func _ready() -> void:
	var tween = create_tween().set_loops()
	tween.tween_property(self, "scale", Vector2(0.95,0.95),1.0)
	tween.tween_property(self, "scale", Vector2(1.1,1.1),1.0)

func set_color(color: Color) -> void:
	color.a = ALPHA_VALUE / 255.0
	modulate = color
