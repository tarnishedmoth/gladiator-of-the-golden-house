class_name StatusEffectParticles extends GPUParticles2D

## One shot particle effects

@export var use_effect_points_as_quantity: bool = true

func _enter_tree() -> void:
	emitting = false
	one_shot = true

func _ready() -> void:
	finished.connect(queue_free)
	restart()
