class_name MouseFollower extends Node2D

@export var affect_parent: bool = false

func _process(_delta: float) -> void:
	if affect_parent:
		get_parent().global_position = get_global_mouse_position()
	else:
		global_position = get_global_mouse_position()
