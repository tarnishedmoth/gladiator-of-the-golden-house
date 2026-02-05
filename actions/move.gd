class_name ActionMove extends Action

## Minimum distance, maximum distance in tiles.
## e.g. if the value is (2, 2), you can only move exactly two tiles.
## If the value is (1, 2), you can move either one or two tiles.
@export var distance: Vector2i = Vector2i(1, 1)

## On transition to this state
func enter(from: ResourceState = null) -> void:
	p("Moving!")
	exit()
