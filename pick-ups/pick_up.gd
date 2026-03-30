class_name PickUp extends Node2D

@export var pick_up_action: Action
@export var ui_name: String
@export var ui_description: String
@export var sprite: Sprite2D

@export var pick_up_data:PickUpData

var current_tile_coords: Vector2i
var tile_map: TileMapLayer
var pick_up_manager: PickUpManager

func setup(manager: PickUpManager, tilemap: TileMapLayer, _pickupdata:PickUpData = null) -> void:
	pick_up_manager = manager
	pick_up_manager.pick_ups.push_back(self)
	self.tile_map = tilemap
	snap_to_nearest_tile()
	
	
	#used for the pickup data that is created throughout the round
	if(_pickupdata):
		apply_data(_pickupdata)
	else:
		apply_data(pick_up_data)# this will be used for the pickup data avaiable at the start of round
	print ("pick up spawned")	

func on_pick_up(actor:Actor) -> void:
	var actor_director: Player = actor.director
	if actor_director:
		actor_director.add_to_deck(pick_up_action)
	clear_pick_up()

func snap_to_nearest_tile() -> void:
	var tile_coords: Vector2i = tile_map.local_to_map(tile_map.to_local(global_position))
	assert(TileInteractor.cell_exists(tile_coords, tile_map))
	global_position = Actor.get_global_position_at(tile_map, tile_coords)
	
	current_tile_coords = tile_coords

func clear_pick_up() -> void:
	pick_up_manager.remove_pick_up(self)
	Juice.fade_out(self).tween_callback(queue_free)

func apply_data(pickupdata:PickUpData) -> void:
	pick_up_action = pickupdata.pick_up_action
	ui_name = pickupdata.ui_name
	ui_description = pickupdata.ui_description
	sprite.texture = pickupdata.texture
	
