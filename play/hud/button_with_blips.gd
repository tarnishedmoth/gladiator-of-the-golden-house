class_name ButtonWithBlips extends Button

@export var blip_prefab: PackedScene = preload("uid://dhwxpcx7ajaji")
@export var blips_container_path: NodePath = ^"Blips"


var blips:Array[CanvasItem] = []

func get_blips_count() -> int:
	return blips.size()
	
func clear_blips() -> void:
	for blip in blips:
		blip.free()
	
	blips.clear()

func set_blips(value:int) -> void:
	if not blips_container_path:
		push_warning("No blips container configured.")
		return
	
	var blips_count: int = blips.size()
	
	if value == blips_count:
		return
		
	elif value < blips_count:
		## Delete some blips
		var container = get_node(blips_container_path)
		if not container:
			push_warning("Got invalid retun from container node path.")
		
		var to_delete:int = blips_count - value
		for i in to_delete:
			var blip = blips.pop_back()
			container.remove_child(blip)
			blip.free()
			
	else:
		## Add some blips
		if not blip_prefab:
			push_warning("No blip prefab assigned.")
			return
		
		for i in (value - blips_count):
			## Add a blip
			var container = get_node(blips_container_path)
			if not container:
				push_warning("Got invalid retun from container node path.")
				return
			else:
				assert(blip_prefab.can_instantiate())
				var new_blip := blip_prefab.instantiate()
				container.add_child(new_blip)
