class_name PickUpManager extends Node2D

@export var pickup_pool: Array [PickupEntry]

@export_group("Spawn extra starting pickups")
## If set to -1, disabled.
## When the player's loss streak is equal to or greater than this number,
## spawns extra pickups to help them progress.
## See [member PlayerData.current_loss_streak].
@export var spawn_extra_starting_pickups_after_loss_streak: int = -1
## Number of pickups to spawn.
@export var spawn_extra_starting_pickups_quantity: int = 1
@export var spawn_ideal_distance_from_player: int = 2:
	get: return maxi(1, spawn_ideal_distance_from_player)
@export var to_spawn: Array[PickupEntry]

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

	if spawn_extra_starting_pickups_after_loss_streak > -1:
		if PlayerData.this.current_loss_streak >= spawn_extra_starting_pickups_after_loss_streak:
			spawn_extra_pickups()

func spawn_extra_pickups() -> void:
	var player_location = Level.get_player_main_character().current_tile_coords
	if not player_location:
		return

	var potential_targets: Array[Vector2i] = Level.get_base_tile_map_layer().get_used_cells()
	potential_targets.sort_custom(
		func(a: Vector2i, b: Vector2i):
			var a_distance_to_player = Cube.distance(Cube.from_axial(a), Cube.from_axial(player_location))
			var b_distance_to_player = Cube.distance(Cube.from_axial(b), Cube.from_axial(player_location))
			if a_distance_to_player == spawn_ideal_distance_from_player:
				return true
			elif b_distance_to_player == spawn_ideal_distance_from_player:
				return false
			elif (a_distance_to_player - spawn_ideal_distance_from_player) < (b_distance_to_player - spawn_ideal_distance_from_player):
				return true
			else:
				return false
	)

	for i in spawn_extra_starting_pickups_quantity:
		var pickup: PickUpData
		if not to_spawn.is_empty():
			pickup = get_weighted_random(to_spawn)
		else:
			pickup = get_weighted_random()
		if not pickup: continue
		
		var location: Vector2i = potential_targets.pop_front()
		assert(location != null)
		spawn_pick_up(pickup, location)


func get_weighted_random(pool: Array[PickupEntry] = pickup_pool) -> PickUpData:
	if pool.is_empty():
		p("Pickup pool for this level is EMPTY")
		return null
	var total := 0.0
	for entry in pool:
		total += entry.weight
	if total <= 0.0:
		return null
	var roll := randf() * total
	for e in pool:
		roll -= e.weight
		if roll <= 0.0:
			return e.data
	return pool[-1].data

func check_if_pickup_already_there(check_cords)->bool: #check if pickup array already has an item at coords
	for each in pick_ups:
		if each.current_tile_coords == check_cords: return true
	return false

#use this to spawn a pick up at a specific coord
func spawn_pick_up(pick_up: PickUpData,coords: Vector2i) -> void:
	if check_if_pickup_already_there(coords): return #if item already there dont spawn a new item
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
