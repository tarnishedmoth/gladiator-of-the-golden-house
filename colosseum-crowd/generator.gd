@tool
extends Node2D

@export var hood: Array[Texture2D]
@export var body: Array[Texture2D]
@export var hair: Array[Texture2D]
@export var clothes: Array[Texture2D]

@onready var _hood: Sprite2D = %Hood
@onready var _body: Sprite2D = %Body
@onready var _hair: Sprite2D = %Hair
@onready var _clothes: Sprite2D = %Clothes


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var flip_all: bool = rand_bool()
	
	if rand_bool(): _hood.texture = hood.pick_random()
	_body.texture = body.pick_random()
	_hair.texture = hair.pick_random()
	_clothes.texture = clothes.pick_random()
	
	if flip_all:
		_hood.flip_h = true
		_body.flip_h = true
		_hair.flip_h = true
		_clothes.flip_h = true
	
	if rand_bool():
		_clothes.flip_h = !_clothes.flip_h

func rand_bool() -> bool:
	return randf() > 0.5
