extends Node2D

signal facing_selected(facing)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

	
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

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
