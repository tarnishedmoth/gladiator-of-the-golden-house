extends Node2D

func _ready():
	
	var dist = 200 # how far we walk in pixels
	var timespan = 5 # how long the tween takes in seconds
	var wait = 5 # wait this many seconds before starting
	var myease = Tween.EASE_OUT # start fast then slow down
	var mytrans = Tween.TRANS_SINE # SINE, BOUNCE, ELASTIC etc
	
	var tween = create_tween()
	var goHere = Vector2(position.x-dist,position.y)
	tween.tween_property(self,"position",goHere,timespan).set_trans(mytrans).set_ease(myease).set_delay(wait) 
