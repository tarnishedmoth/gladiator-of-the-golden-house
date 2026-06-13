class_name PickUp extends Node2D

const ONESHOT_SFX = preload("uid://b7fbgvg5xlb68")

@export var pick_up_action: Action
@export var ui_name: String
@export var ui_description: String ## DEPRECATED generating a description and utilizing the Action's description for UI.
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

## Picked-up actions go to the player's stash (persistent bonus cards) rather than the draw deck.
func on_pick_up(actor:Actor) -> void:
	if actor.director is Player:
		var player_director: Player = actor.director
		var card_copy: Action = pick_up_action.duplicate()
		SaveUid.tag_duplicate(pick_up_action, card_copy)
		player_director.add_to_stash(card_copy)
		
		var sfx: AudioStreamPlayer2D = ONESHOT_SFX.instantiate()
		tile_map.add_child(sfx)
		if not sfx.autoplay: sfx.play()
	else:
		push_warning("Actor called PickUp.on_pick_up not Player")
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
	
