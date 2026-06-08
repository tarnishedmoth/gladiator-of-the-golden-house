extends Node2D

const ANIMATE_OFFSET: bool = true
const ANIMATE_SCALE: bool = true

signal facing_selected(facing)

@onready var north_sprite: Sprite2D = $North/NorthSprite
@onready var south_sprite: Sprite2D = $South/SouthSprite
@onready var south_west_sprite: Sprite2D = $SouthWest/SouthWestSprite
@onready var south_east_sprite: Sprite2D = $SouthEast/SouthEastSprite
@onready var north_west_sprite: Sprite2D = $NorthWest/NorthWestSprite
@onready var north_east_sprite: Sprite2D = $NorthEast/NorthEastSprite
@onready var panel_container: PanelContainer = $PanelContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	tween_the_sprites()
	panel_container.show()

func tween_the_sprites():
	for sprite: Sprite2D in [
		north_sprite,
		north_west_sprite,
		north_east_sprite,
		south_sprite,
		south_west_sprite,
		south_east_sprite,
		]:
		
		if ANIMATE_SCALE:
			Juice.scale_pulse(sprite, 0.8, 1.0, Juice.SNAPPY)
		
		if ANIMATE_OFFSET:
			var tween = sprite.create_tween().set_loops()
			tween.tween_property(sprite, ^"offset:y", -8.0, Juice.SMOOTH)
			tween.tween_property(sprite, ^"offset:y", 0.0, Juice.SMOOTH)
	
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
