class_name StateMachine extends Node

enum StartBehavior {
	MANUAL,
	ON_READY,
}

@export var start_behavior:StartBehavior = StartBehavior.MANUAL
@export var initial_state: State
@export var return_to_initial_state: bool = true
@export var debug: bool = false

var current_state: State
var states: Array[State]

func p(args) -> void:
	print_rich("[bgcolor=khaki][color=black]StateMachine: ", args)

func _ready() -> void:
	if debug: p("\n" + get_parent().name + "\n" + get_tree_string_pretty())
	if start_behavior == StartBehavior.ON_READY:
		start()
	
func start() -> void:
	populate_from_children()
	change_state(initial_state)
	
func populate_from_children(and_connect_signals: bool = true) -> void:
	for child in get_children():
		if child is State:
			if not child in states:
				states.append(child)
				if and_connect_signals:
					if not child.finished.is_connected(_on_state_finished):
						child.finished.connect(_on_state_finished)
				
func clear_states(): states.clear() ## Does not stop or set current state.
func pause(): stop() ## Alias for [method stop].
func stop(): ## Technically a "pause"
	if current_state:
		current_state.process(false)
		
func resume():
	if current_state:
		current_state.process(true)

func change_state(new_state: State = null, source: State = null) -> void:
	stop()
	
	if not new_state:
		if return_to_initial_state && initial_state:
			new_state = initial_state
			if debug: p("Resetting to initial state.")
		else:
			if debug: p("Inactive! No state.")
			return
	
	current_state = new_state
	if debug: new_state.debug = true
	new_state.process(true)
	new_state.enter(source)
	if debug: p("Entered: %s  from  %s" % [current_state, source])

func send_event(message) -> void:
	for state in states:
		if debug: p("Propagating message to state: %s" % state)
		state.on_event(message)
	
func _on_state_finished(next: State, source: State) -> void:
	change_state(next, source)
