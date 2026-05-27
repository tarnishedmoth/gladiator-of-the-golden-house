extends Control

signal finished

@export_range(4.0, 300.0, 1.0, "or_greater", "suffix:seconds") var iterative_duration: float = 20.0 ## Total playtime.

var nodes: Array[CanvasItem] = []

func _enter_tree() -> void:
	hide()

func _ready() -> void:
	nodes.append_array(get_children())
	for ci:CanvasItem in nodes:
		ci.hide()
		ci.modulate = Color.TRANSPARENT
	
	await get_tree().create_timer(0.5).timeout
	start_reveal_iter()
	show()


var iter_current:int
var pages:int
var tick_interval:float
var ticker:Tween
func start_reveal_iter() -> void:
	print("starting iterative reveal")
	#for group:Array in groups:
		#for ci:CanvasItem in group:
			#ci.hide()
	
	iter_current = -1
	
	pages = nodes.size()
	tick_interval = iterative_duration / (pages)
	_on_iterative_tick()
	ticker = create_tween()
	ticker.set_loops(pages)
	ticker.tween_interval(tick_interval)
	ticker.tween_callback(_on_iterative_tick)
	#ticker.finished.connect(_on_ticker_finished) ## Need to let the ticker execute and quit
	
	
func _on_iterative_tick() -> void:
	print("iterative tick")
	iter_current += 1
	
	var fade_time:float = tick_interval / 8.0
	var clear_time:float = fade_time
	var remainder:float = tick_interval - clear_time - (fade_time * 2)

	#for ci:CanvasItem in groups[iter_current_group]:
	var ci = nodes[iter_current]
	
	var tween:Tween = create_tween()
	## Fade In
	tween.tween_property(ci, ^"modulate", Color.WHITE, fade_time).from(Color.TRANSPARENT)
	## Show time
	tween.tween_interval(remainder)
	## Fade Out
	tween.tween_property(ci, ^"modulate", Color.TRANSPARENT, fade_time)
	## Clear time
	## (do nothing, tween is finished)
	ci.show()
	#ci.show.call_deferred()
		
	if iter_current + 1 >= nodes.size():
		ticker.kill()
		await create_tween().tween_interval(tick_interval * 1.15).finished
		_on_ticker_finished()

func _on_ticker_finished() -> void:
	## Exit the credits scene
	finished.emit()
