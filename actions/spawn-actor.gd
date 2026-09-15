class_name ActionSpawn extends Action

@export_file("*.tscn") var actor_to_spawn ## Should be an [Actor] scene.

@export var pattern: Array[Vector2i] = [Facing.DIRECTIONS[Facing.Cardinal.NORTH]]
@export var face_to_player: bool = true
@export var insert_at_front_of_play_sequence: bool = true

@export var spawn_at_all_tiles: bool = false ## If true, spawns one actor on every tile in the [member pattern].

func enter(_from: ResourceState = null) -> void:
	var _actor_scene: PackedScene = ResourceLoader.load(actor_to_spawn, "PackedScene", ResourceLoader.CACHE_MODE_REUSE)
	
	if spawn_at_all_tiles:
		spawn_actors_at_all_tiles(_actor_scene)
	else:
		spawn_actor(_actor_scene, _target)
	exit()
	
func spawn_actors_at_all_tiles(scene: PackedScene) -> void:
	var tiles: Array[Vector2i] = _actor.get_translated_pattern_without_obstructions(pattern)
	p("Spawning actors at %d tiles..." % tiles.size())
	
	for tile: Vector2i in tiles:
		spawn_actor(scene, tile)

func spawn_actor(scene: PackedScene, at: Vector2i) -> void:
	if at == null:
		p("Null target, exiting...\n(this could be due to AI skipping planning because of some preventing factor)")
		return
	
	if not _actor:
		push_error("ActionSpawn: Invalid or empty source actor.")
		return
	var director = _actor.director as AIDirector
	if not director:
		push_error("ActionSpawn: Invalid or empty source actor.")
		return
	
	if not scene:
		push_error("ActionSpawn: Invalid or empty scene to spawn.")
		return
	if not scene.can_instantiate():
		push_error("ActionSpawn: Can't instantiate scene.")
		return
		
	if not can_spawn_actor_at(at):
		if debug: p("Can't spawn actor at coordinate %s. Exiting." % at)
		return
	
	var actor: Actor = scene.instantiate()
	if not actor is Actor:
		push_error("ActionSpawn: Instantiated scene is not Actor. Deleting...")
		actor.free()
		return
	
	if debug: p("Spawning %s at %s..." % [actor, at])
	
	## VFX
	actor.modulate = Color.TRANSPARENT
	var actor_fader: Tween = actor.create_tween()
	actor_fader.tween_property(actor, ^"modulate", Color.WHITE, Juice.SMOOTH)
	
	
	## By default we want to insert children at the top, so that they now go first each turn.
	director.add_child(actor)
	
	if insert_at_front_of_play_sequence:
		director.move_child(actor, 0)
	
	## Set the actors position to tile coordinate
	var tile_map: TileMapLayer = Level.get_base_tile_map_layer()
	actor.global_position = Actor.get_global_position_at(tile_map, at)
	
	if face_to_player:
		var player: Actor = Level.get_all_actors_in_play_order().filter(func(v: Actor): return v.director is Player).front()
		if player:
			actor.facing = Facing.get_direction_to_cell(tile_map, at, player.current_tile_coords)
	
	## Inject into a director
	director.add_actor_for_next_turn(actor, insert_at_front_of_play_sequence)
	actor.snap_to_nearest_tile()
	
	## Profit?

func can_spawn_actor_at(tile_coord: Vector2i) -> bool:
	return false if Level.get_actor_at(tile_coord) else true
