extends Node2D

@export var fully_underground_rotation: float = -170.0
@export var retracted_rotation: float = -130.0
@export var extended_rotation: float = 0.0

@export var timespanIn: float = 0.5;
@export var timespanOut: float = 2.0;

@export var pre_emerging_wait_time: float = 2.5
@export var emerging_time: float = 5.0

var animation: Tween
func _ready():
	await spring_from_ground()
	idle_loop()


func spring_from_ground() -> Signal:
	rotation = deg_to_rad(fully_underground_rotation)
	
	_animation_check_kill()
	animation = create_tween()
	animation.set_trans(Tween.TRANS_LINEAR)
	animation.tween_interval(pre_emerging_wait_time)
	
	var time_to_emerge: float = emerging_time + rand_offset()
	animation.tween_property(self, "rotation", deg_to_rad(extended_rotation), time_to_emerge)
	
	return animation.finished

func idle_loop() -> void:
	_animation_check_kill()
	animation = create_tween()
	
	animation.set_loops() # loop forever
	animation.set_parallel(false) # one after another
	timespanIn += rand_offset()
	timespanOut += rand_offset()
	animation.set_trans(Tween.TRANS_SINE)
	animation.tween_property(self, "rotation", deg_to_rad(extended_rotation), timespanIn) # back
	animation.tween_property(self, "rotation", deg_to_rad(extended_rotation), timespanIn) # wait
	animation.tween_property(self, "rotation", deg_to_rad(retracted_rotation), timespanOut) # and forth
	
func _animation_check_kill() -> void:
	if animation: animation.kill()

func rand_offset() -> float:
	return randf_range(-0.2,0.2)
