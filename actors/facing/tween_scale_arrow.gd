extends Node2D

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:

	var tween := create_tween().set_loops()
	tween.tween_property(self, "scale:y", 1.0, 1.2)
	tween.tween_property(self, "scale:y", .9, 1.2)
