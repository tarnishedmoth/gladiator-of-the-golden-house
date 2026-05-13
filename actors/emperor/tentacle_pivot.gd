extends Node2D

@export var startRotation:float = 130.0
@export var endRotation:float = 0.0
@export var timespanIn:float = 0.5;
@export var timespanOut:float = 2.0;

func _ready():
	var tween = create_tween()
	# rotation = randf_range(startRotation, endRotation) # so they aren't in synch
	tween.set_loops() # loop forever
	tween.set_parallel(false) # one after another
	timespanIn += randf_range(-0.2,0.2)
	timespanOut += randf_range(-0.2,0.2)
	tween.tween_property(self, "rotation", deg_to_rad(endRotation), timespanIn).set_trans(Tween.TRANS_SINE) # back
	tween.tween_property(self, "rotation", deg_to_rad(endRotation), timespanIn).set_trans(Tween.TRANS_SINE) # wait
	tween.tween_property(self, "rotation", deg_to_rad(startRotation), timespanOut).set_trans(Tween.TRANS_SINE) # and forth
