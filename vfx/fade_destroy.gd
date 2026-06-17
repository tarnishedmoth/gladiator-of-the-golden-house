extends Sprite2D

@export var time: float = 0.75

func _ready() -> void:
	Juice.fade_out(self, time).finished.connect(queue_free)
