class_name ButtonWithBlips extends Button

const BLIP_PREFAB: PackedScene = preload("uid://dhwxpcx7ajaji")
var blips_container: HBoxContainer

var blips:Array[CanvasItem] = []

func _enter_tree() -> void:
	if not blips_container:
		blips_container = HBoxContainer.new()
		blips_container.custom_minimum_size.y = 6.0
		blips_container.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		blips_container.alignment = BoxContainer.ALIGNMENT_END
		add_child(blips_container)

func get_blips_count() -> int:
	return blips.size()
	
func clear_blips() -> void:
	for blip in blips:
		blip.free()
	
	blips.clear()

func set_blips(value:int) -> void:
	if not blips_container:
		push_warning("No blips container configured.")
		return
	
	var blips_count: int = blips.size()
	
	if value == blips_count:
		return
		
	elif value < blips_count:
		## Delete some blips
		if not blips_container:
			push_warning("Got invalid retun from container node path.")
		
		var to_delete:int = blips_count - value
		for i in to_delete:
			var blip = blips.pop_back()
			blips_container.remove_child(blip)
			blip.free()
			
	else:
		## Add some blips
		if not BLIP_PREFAB:
			push_warning("No blip prefab assigned.")
			return
		
		for i in (value - blips_count):
			## Add a blip
			if not blips_container:
				push_warning("Got invalid retun from container node path.")
				return
			else:
				assert(BLIP_PREFAB.can_instantiate())
				var new_blip := BLIP_PREFAB.instantiate()
				blips_container.add_child(new_blip)
