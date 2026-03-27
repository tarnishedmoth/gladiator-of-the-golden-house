class_name PickUpManager extends Node2D

var pick_ups: Array[PickUp]
var tile_map: TileMapLayer
var pick_up_template:= preload("res://pick-ups/pick_up.tscn")


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func setup(tilemap: TileMapLayer) -> void:
	tile_map = tilemap
	for child in self.get_children():
		if child is PickUp:
			child.setup(self,tilemap)

#use this to spawn a pick up at a specific coord
func spawn_pick_up(pick_up: PickUpData,coords: Vector2i) -> void:

	var pick_up_instance: PickUp = pick_up_template.instantiate()
	add_child(pick_up_instance)
	pick_up_instance.global_position = Actor.get_global_position_at(tile_map,coords)
	pick_up_instance.name = "Pick_Up" + str(pick_ups.size()) 
	
	pick_up_instance.setup(self,tile_map,pick_up)
	

#use this to remove a pick up
func remove_pick_up(pick_up: PickUp) -> void:
	var pick_up_index: int = pick_ups.find(pick_up)
	if(pick_up_index != -1):
		pick_ups.remove_at(pick_up_index)
