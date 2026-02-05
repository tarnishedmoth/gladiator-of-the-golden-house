class_name ActionAttack extends Action

@export var damage: int

## On transition to this state
func enter(from: ResourceState = null) -> void:
	## TODO
	## get affected tiles
	## deal damage to anything there
	## ???
	## profit
	p("Attacking!")
	exit()
