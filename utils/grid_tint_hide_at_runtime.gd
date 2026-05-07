extends Polygon2D

@export var show_guide_in_game = false

func _ready() -> void:
	if not show_guide_in_game:
		hide()
	else:
		show()
