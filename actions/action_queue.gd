class_name ActionQueue

## A lean state machine for sequentially running [Action]s.
signal queue_size_changed(new_size: int)
signal finished

var debug: bool = true
var target: Actor

var current_action: Action
var queue: Array[Action]

var running_queue:bool = false

func p(args) -> void:
	print_rich("[bgcolor=olive][color=white]%s ActionQueue: " % target, args)
	
func run_queue() -> void:
	running_queue = true
	queue_size_changed.emit(queue.size() - 1)
	run_action(queue.pop_front())

func run_action(new_action: Action = null, source: Action = null) -> void:
	if not new_action:
		current_action = null
		finished.emit.call_deferred()
		if debug: p("Deactivating. Queue size is %d." % queue.size())
	else:
		current_action = new_action
		if debug:
			new_action.debug = true
			p("Entering: %s  from  %s" % [current_action, source])
		new_action.finished.connect(_on_action_finished, ConnectFlags.CONNECT_ONE_SHOT)
		new_action.process(true)
		new_action.enter(source)
	
## If chain_next is empty, the next item in the queue, if any, will be popped.
func _on_action_finished(chain_next: ResourceState, source: ResourceState) -> void:
	if (not chain_next) and running_queue:
		chain_next = queue.pop_front()
		if chain_next:
			queue_size_changed.emit(queue.size())
			if debug: p("Popped next action.")
		
	run_action(chain_next, source)
