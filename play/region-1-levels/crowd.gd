extends Node2D

## Procedurally spawns generators on points (puts people in seats)

const GENERATOR = preload("uid://0b8prxcp20px")
@export var polygons: Array[Polygon2D]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for poly in polygons:
		for point in poly.polygon:
			# Make a crowd guy
			var new_crowd_blob: Node2D = GENERATOR.instantiate()
			add_child(new_crowd_blob)
			new_crowd_blob.position = (point * poly.scale) + poly.position
			
			var tween: Tween = new_crowd_blob.create_tween()
			var duration: float = randf_range(1.0, 5.0)
			tween.tween_property(new_crowd_blob, ^"scale:y", 1.0, duration).from(0.0)
			tween.parallel()
			tween.tween_property(new_crowd_blob, ^"modulate", Color.WHITE, duration).from(Color.TRANSPARENT)
