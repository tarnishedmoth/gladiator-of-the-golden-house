extends Sprite2D

# wobbles a sprite up and down

@export var speed := 5.0
@export var amplitude := 4.0
var original_y: float

func _ready():
	original_y = position.y

func _process(_delta):
	var new_y = original_y + (sin(Time.get_ticks_msec() / 1000.0 * speed) * amplitude)
	position.y = new_y
