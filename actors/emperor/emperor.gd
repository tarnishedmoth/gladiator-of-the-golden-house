class_name VisualEmperor extends Node2D

## Performs the act of the emperor prior to entering combat
@export var run_random_oneliners: bool = true
@export var one_liners: OneLiners

func _ready():
	subscribe_to_level_event()
	if one_liners:
		one_liners.run_random_triggers = run_random_oneliners
	
	animate_delayed_entrance()

func animate_delayed_entrance() -> void:
	var dist = 200 # how far we walk in pixels
	var timespan = 5 # how long the tween takes in seconds
	var wait = 5 # wait this many seconds before starting
	var myease = Tween.EASE_OUT # start fast then slow down
	var mytrans = Tween.TRANS_SINE # SINE, BOUNCE, ELASTIC etc
	
	var tween = create_tween()
	var goHere = Vector2(position.x-dist,position.y)
	tween.tween_property(self,"position",goHere,timespan).set_trans(mytrans).set_ease(myease).set_delay(wait)

## forced failure level event reaction
func subscribe_to_level_event() -> void:
	var level = Level.instance
	if level:
		if level.has_signal(&"event"):
			level.connect(&"event", on_level_event)

func on_level_event() -> void:
	if one_liners:
		one_liners.say_this_oneliner("Let's see you handle this!!")
