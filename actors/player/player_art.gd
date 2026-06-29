extends Node2D

func _enter_tree() -> void:
	replace_art.call_deferred()

func replace_art() -> void:
	## Replace ourself and die
	var scene = PlayerData.this.get_character_scene()
	var instance = scene.instantiate()
	var actor_parent := get_parent() as Actor
	
	if "modulate" in instance:
		instance.modulate = modulate
	replace_by(instance)
	
	if actor_parent:
		actor_parent.character_visual_root = instance
	
	queue_free()
