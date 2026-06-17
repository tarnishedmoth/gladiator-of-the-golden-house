class_name TargetIndicatorVisual extends Node2D

const ALPHA_VALUE = 114

@export var fill: CanvasItem

var animate_on_enter: bool = true
var show_fill: bool = false

var _despawning: bool = false
@onready var _starting_scale: Vector2 = scale

func _ready() -> void:
	if fill:
		fill.visible = show_fill
	
	if animate_on_enter:
		var tween = create_tween()
		tween.tween_property(self, ^"modulate", modulate, Juice.BLITZ).from(Color.TRANSPARENT)
		tween.tween_callback(pulse)

func pulse() -> void:
	var tween = create_tween().set_loops()
	tween.tween_property(self, "scale", Vector2(0.95,0.95) * _starting_scale, 1.0)
	tween.tween_property(self, "scale", Vector2(1.1,1.1) * _starting_scale, 1.0)

func set_color(color: Color) -> void:
	color.a = ALPHA_VALUE / 255.0
	modulate = color

func despawn() -> void:
	if not _despawning:
		_despawning = true
		Juice.fade_out(self, Juice.SNAP).tween_callback(queue_free)
