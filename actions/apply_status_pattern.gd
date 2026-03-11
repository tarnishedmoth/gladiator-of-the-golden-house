class_name ActionApplyStatusPattern extends ActionApplyStatus

@export var pattern: Array[Vector2i] = [] ## Assume coords 0,0 and facing north. Then list the coords they can hit. the rotate hex function in facing will make that pattern work in any direction.
@export var aoe_pattern: Array[Vector2i]
@export var split_choice: bool = false ## TODO If true, allows for the pattern to *also* apply counter-clockwise. This is specifically for asymmetrical patterns.



# Called when the node enters the scene tree for the first time.
func enter(from: ResourceState = null) -> void:
	if status:
		_get_affected_and_apply_status()
	exit()

func _get_affected_and_apply_status() -> void:
	var targets: Array[Vector2i] = _actor.get_translated_pattern(pattern)

	if debug: p("Targeting %d tiles." % targets.size())

	for coords in targets:
		var found_actor: Actor = Level.get_actor_at(coords)
		if found_actor:
			apply_status(found_actor)

