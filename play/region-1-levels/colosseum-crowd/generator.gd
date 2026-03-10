@tool
class_name NPCVisualRandomizer extends Node2D

enum Face {
	LEFT,
	RIGHT,
	RANDOM
}

@export var hood: Array[Texture2D]
@export var body: Array[Texture2D]
@export var hair: Array[Texture2D]
@export var clothes: Array[Texture2D]

@onready var _hood: Sprite2D = %Hood
@onready var _body: Sprite2D = %Body
@onready var _hair: Sprite2D = %Hair
@onready var _clothes: Sprite2D = %Clothes


# Called when the node enters the scene tree for the first time.
func _ready():
	if rand_bool(): _hood.texture = hood.pick_random()
	_body.texture = body.pick_random()
	_hair.texture = hair.pick_random()
	_clothes.texture = clothes.pick_random()
	
	if rand_bool():
		_clothes.flip_h = !_clothes.flip_h
		
func face(direction: Face):
	if direction == Face.LEFT:
		_hood.flip_h = true
		_body.flip_h = true
		_hair.flip_h = true
	elif direction == Face.RANDOM:
		if rand_bool():
			_hood.flip_h = true
			_body.flip_h = true
			_hair.flip_h = true

func rand_bool() -> bool:
	return randf() > 0.5
