extends Node2D

signal facing_selected(facing)
@onready var north_sprite: Sprite2D = $North/NorthSprite
@onready var south_sprite: Sprite2D = $South/SouthSprite
@onready var south_west_sprite: Sprite2D = $SouthWest/SouthWestSprite
@onready var south_east_sprite: Sprite2D = $SouthEast/SouthEastSprite
@onready var north_west_sprite: Sprite2D = $NorthWest/NorthWestSprite
@onready var north_east_sprite: Sprite2D = $NorthEast/NorthEastSprite


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	tween_the_sprites()

func tween_the_sprites():
	Juice.scale_pulse(north_sprite,.85,1.0,.8)
	Juice.scale_pulse(north_west_sprite,.85,1.0,.8)
	Juice.scale_pulse(north_east_sprite,.85,1.0,.8)
	Juice.scale_pulse(south_sprite,.85,1.0,.8)
	Juice.scale_pulse(south_east_sprite,.85,1.0,.8)
	Juice.scale_pulse(south_west_sprite,.85,1.0,.8)
	
func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:		
		get_viewport().set_input_as_handled()
		print("detected click: ", get_global_mouse_position())
		var space = get_world_2d().direct_space_state
		var query = PhysicsPointQueryParameters2D.new()
		query.collide_with_areas = true
		query.collide_with_bodies = false  
		query.position = get_global_mouse_position()
		query.collision_mask = 0xFFFFFFFF
		var results = space.intersect_point(query)		
		for r in results:
			match r.collider.name:
				"North":					
					print("north selected")
					facing_selected.emit(Facing.Cardinal.NORTH)
					return
				"South":
					print("south selected")
					facing_selected.emit(Facing.Cardinal.SOUTH)
					return
				"SouthWest":
					print("southwest selected")
					facing_selected.emit(Facing.Cardinal.SOUTHWEST)
					return
				"SouthEast":
					print("soutch east selected")
					facing_selected.emit(Facing.Cardinal.SOUTHEAST)
					return
				"NorthWest":
					print("northwest selected")
					facing_selected.emit(Facing.Cardinal.NORTHWEST)
					return
				"NorthEast":
					print("northeast selected")
					facing_selected.emit(Facing.Cardinal.NORTHEAST)
					return
