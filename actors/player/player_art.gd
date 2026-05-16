extends Node2D

func _enter_tree() -> void:
	replace_art.call_deferred()

func replace_art() -> void:
	## Replace ourself and die
	var scene = PlayerData.this.get_character_scene()
	var instance = scene.instantiate()
	replace_by(instance)
	queue_free()
