class_name CrowdSfx extends Node2D

var use_negative_reactions: bool = true

@export var disabled: bool = false

enum Sounds {
	INTRO = 0,
	MAD = 1,
	SHOCKED = 2,
	HAPPY_1 = 3,
	HAPPY_2 = 4,
	IDLE = 5,
}

@onready var intro: AudioStreamPlayer = $Intro
@onready var mad: AudioStreamPlayer = $Mad
@onready var shocked: AudioStreamPlayer = $Shocked
@onready var happy_1: AudioStreamPlayer = $Happy1
@onready var happy_2: AudioStreamPlayer = $Happy2
@onready var idle: AudioStreamPlayer = $Idle

func play(which: Sounds) -> void:
	if disabled:
		return
	match which:
		Sounds.INTRO:
			intro.play()
		Sounds.MAD:
			if use_negative_reactions:
				mad.play()
		Sounds.SHOCKED:
			shocked.play()
		Sounds.HAPPY_1:
			happy_1.play()
		Sounds.HAPPY_2:
			happy_2.play()
		Sounds.IDLE:
			idle.play()
