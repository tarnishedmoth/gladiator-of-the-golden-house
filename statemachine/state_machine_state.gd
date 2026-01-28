class_name State extends Node

signal finished(next:State, source:State)

@export var next_state: State
@export var debug: bool = false

var run:bool = false:
	set(value):
		run = value
		if run:
			set_process(true)
		else:
			set_process(false)
			
func process(set_to: bool) -> void:
	run = set_to

func p(args) -> void:
	print_rich("[bgcolor=khaki][color=black]State: ", args)

## On transition to this state
func enter(from: State = null) -> void:
	pass
	
## When leaving this state
func exit() -> void:
	finished.emit(
		next_state if next_state else null,
		self
		)

func on_event(message) -> void:
	pass
