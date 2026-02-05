class_name ResourceStateMachine extends Node

enum StartBehavior {
	MANUAL,
	ON_READY,
}

@export var start_behavior:StartBehavior = StartBehavior.MANUAL
@export var initial_state: ResourceState
@export var return_to_initial_state: bool = true
@export var debug: bool = false

var current_state: ResourceState
@export var states: Array[ResourceState]

func p(args) -> void:
	print_rich("[bgcolor=khaki][color=black]StateMachine: ", args)

func _ready() -> void:
	if debug: p("\n" + get_parent().name + "\n" + get_tree_string_pretty())
	if start_behavior == StartBehavior.ON_READY:
		start()
	
func start() -> void:
	change_state(initial_state)
	
func populate_from_list(list:Array[ResourceState], and_connect_signals: bool = true) -> void:
	for item in list:
		if not item in states:
			states.append(item)
			if and_connect_signals:
				if not item.finished.is_connected(_on_state_finished):
					item.finished.connect(_on_state_finished)
				
func clear_states(): states.clear() ## Does not stop or set current state.
func pause(): stop() ## Alias for [method stop].
func stop(): ## Technically a "pause"
	if current_state:
		current_state.process(false)
		
func resume():
	if current_state:
		current_state.process(true)

func change_state(new_state: ResourceState = null, source: ResourceState = null) -> void:
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
	
func _on_state_finished(next: ResourceState, source: ResourceState) -> void:
	change_state(next, source)
