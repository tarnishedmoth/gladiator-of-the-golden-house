class_name PickUpManager extends Node2D

@export var pickup_pool: Array [PickupEntry]

func p(args):
	print_rich("[bgcolor=black][color=blue]", "Pickup Manager: ", args)

var pick_ups: Array[PickUp]
var tile_map: TileMapLayer
var pick_up_template:= preload("res://pick-ups/pick_up.tscn")

func _ready()->void:
	if pickup_pool == null:
		p("Pickup pool for this level is EMPTY")

func setup(tilemap: TileMapLayer) -> void:
	tile_map = tilemap
	for child in self.get_children():
		if child is PickUp:
			child.setup(self,tilemap)

func get_weighted_random() -> PickUpData:	
	if pickup_pool.is_empty():
		return null
	var total := 0.0
	for entry in pickup_pool:		
		total += entry.weight
	if total <= 0.0:
		return null
	var roll := randf() * total
	for e in pickup_pool:
		roll -= e.weight
		if roll <= 0.0:
			return e.data
	return pickup_pool[-1].data


#use this to spawn a pick up at a specific coord
func spawn_pick_up(pick_up: PickUpData,coords: Vector2i) -> void:
	var pick_up_instance: PickUp = pick_up_template.instantiate()
	add_child(pick_up_instance)
	pick_up_instance.global_position = Actor.get_global_position_at(tile_map,coords)
	pick_up_instance.name = "Pick_Up" + str(pick_ups.size()) 
	
	pick_up_instance.setup(self,tile_map,pick_up)
	
	p("Spawned new pick-up at %s." % coords)
	

#use this to remove a pick up
func remove_pick_up(pick_up: PickUp) -> void:
	var pick_up_index: int = pick_ups.find(pick_up)
	if(pick_up_index != -1):
		pick_ups.remove_at(pick_up_index)
		p("Removed pick-up %s." % pick_up.ui_name)
