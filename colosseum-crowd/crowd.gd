extends Node2D

## Procedurally spawns generators on points (puts people in seats)
const GENERATOR = preload("uid://0b8prxcp20px")
const CENTER_BAND: float = 8*32 ## Eight person wide area in center where they can face left or right.

@export var polygons: Array[Polygon2D]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for poly in polygons:
		for point in poly.polygon:
			# Make a crowd guy
			var new_crowd_blob: NPCVisualRandomizer = GENERATOR.instantiate()
			
			## Add him to the scene
			add_child(new_crowd_blob)
			
			## Move him to a position acquired from our polygon
			new_crowd_blob.position = (point * poly.scale) + poly.position
			
			## Change the facing direction based on where in the arena they are.
			if -CENTER_BAND/2 < new_crowd_blob.position.x && new_crowd_blob.position.x < CENTER_BAND/2:
				new_crowd_blob.face(NPCVisualRandomizer.Face.RANDOM)
			elif new_crowd_blob.position.x > position.x:
				## This guy is on the right side of center.
				new_crowd_blob.face(NPCVisualRandomizer.Face.LEFT)
				## Default is facing right so no need to "else"
			
			var tween: Tween = new_crowd_blob.create_tween()
			var duration: float = randf_range(1.0, 5.0)
			tween.tween_property(new_crowd_blob, ^"scale:y", 1.0, duration).from(0.0)
			tween.parallel()
			tween.tween_property(new_crowd_blob, ^"modulate", Color.WHITE, duration).from(Color.TRANSPARENT)
