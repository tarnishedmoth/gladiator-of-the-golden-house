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

var baked: Sprite2D

@onready var _hood: Sprite2D = %Hood
@onready var _body: Sprite2D = %Body
@onready var _hair: Sprite2D = %Hair
@onready var _clothes: Sprite2D = %Clothes


# Called when the node enters the scene tree for the first time.
func _ready():
	make_blob()
	bake_blob()

## Randomizes the blob bro.
func make_blob() -> void:
	if rand_bool(): _hood.texture = hood.pick_random()
	_body.texture = body.pick_random()
	_hair.texture = hair.pick_random()
	_clothes.texture = clothes.pick_random()
	
	if rand_bool():
		_clothes.flip_h = !_clothes.flip_h

## Render the layered sprites down into one texture to reduce draw calls bro.
func bake_blob() -> void:
	if baked:
		baked.queue_free()
	baked = Sprite2D.new()
	baked.name = "Bake"
	
	var textures: Array[Texture2D]
	## Order is important.
	if _hood.texture: textures.append(_hood.texture)
	textures.append(_body.texture)
	textures.append(_hair.texture)
	textures.append(_clothes.texture)
	
	baked.texture = BlobOven.bake(textures)
	add_child(baked)
	
	## Clear the separate sprites to clear memory bro.
	_hood.queue_free()
	_body.queue_free()
	_clothes.queue_free()
	_hair.queue_free()

func face(direction: Face):
	if direction == Face.LEFT:
		baked.flip_h = true
		#_hood.flip_h = true
		#_body.flip_h = true
		#_hair.flip_h = true
	elif direction == Face.RANDOM:
		if rand_bool():
			baked.flip_h = true
			#_hood.flip_h = true
			#_body.flip_h = true
			#_hair.flip_h = true

func rand_bool() -> bool:
	return randf() > 0.5
