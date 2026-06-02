class_name PlayerInsertPlaceholder extends Node2D

## Will replace itself with a referenced scene via [PlayerData].
## See [method Player.

func replace() -> void:
	## Replace self with the appropriate scene.
	assert(PlayerData.this)
	var scene: PackedScene = PlayerData.this.get_chosen_starting_class_scene()
	var instance: Player = scene.instantiate()
	
	add_sibling(instance)
	instance.global_position = self.global_position
	queue_free()

func _enter_tree() -> void:
	## prevent from showing in the game for even a frame
	hide()
