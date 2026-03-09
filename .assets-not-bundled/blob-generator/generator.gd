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
	_hood.texture = hood.pick_random()
	_body.texture = body.pick_random()
	_hair.texture = hair.pick_random()
	_clothes.texture = clothes.pick_random()
	
	if randf() > 0.5:
		_clothes.flip_h = true
