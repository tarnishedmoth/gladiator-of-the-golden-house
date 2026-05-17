class_name ActionCreateTileWatcher extends Action

@export var tile_watcher: PackedScene ## [TileWatcher]
@export var pattern: Array[Vector2i] = [Vector2i(0, -1)]

func enter(from: ResourceState = null) -> void:
	if tile_watcher:
		if is_obstructable:
			if Level.get_actor_at(_target):
				exit()
				return
		_spawn()
	exit()

func _spawn() -> void:
	if debug: p("Spawning tile watcher")

	var instance: TileWatcher = tile_watcher.instantiate()
	_actor.director.add_child(instance)
	instance.setup(_target, _actor)
