@abstract class_name ResourceState extends Resource

signal finished(next:ResourceState, source:ResourceState)

@export var next_state: ResourceState
@export var debug: bool = false

var run:bool = false:
	set(value):
		run = value
			
func process(set_to: bool) -> void:
	run = set_to

func p(args) -> void:
	print_rich("[bgcolor=khaki][color=black]State: ", args)

## On transition to this state
@abstract func enter(from: ResourceState = null) -> void

## When leaving this state
func exit() -> void:
	finished.emit(
		next_state if next_state else null,
		self
		)

func on_event(message) -> void:
	pass
