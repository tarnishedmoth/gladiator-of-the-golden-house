class_name CrowdSfx extends Node2D

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
	match which:
		Sounds.INTRO:
			intro.play()
		Sounds.MAD:
			mad.play()
		Sounds.SHOCKED:
			shocked.play()
		Sounds.HAPPY_1:
			happy_1.play()
		Sounds.HAPPY_2:
			happy_2.play()
		Sounds.IDLE:
			idle.play()
