class_name ActionAttack extends Action

@export var damage: int
@export_category("ATK Pattern Directions & Ranges Enabled")
@export var front: Array[int]
@export var front_right: Array[int]
@export var back_right: Array[int]
@export var back: Array[int] 
@export var back_left: Array[int]
@export var front_left: Array[int]

## On transition to this state
func enter(from: ResourceState = null) -> void:
	#if debug:
	p("Attacking!")
	
	## run animations etc here
	get_affected_and_deal_damage()
	
	exit()

func get_pattern() -> Array:
	var pattern = []
	for r in front:
		pattern.append([Facing.Relative.FRONT, r])
	for r in front_right:
		pattern.append([Facing.Relative.FRONT_RIGHT, r])
	for r in back_right:
		pattern.append([Facing.Relative.BACK_RIGHT, r])
	for r in back:
		pattern.append([Facing.Relative.BACK, r])
	for r in back_left:
		pattern.append([Facing.Relative.BACK_LEFT, r])
	for r in front_left:
		pattern.append([Facing.Relative.FRONT_LEFT, r])
	return pattern

func get_affected_and_deal_damage() -> void:
	#this should be ready to hook into the target configuration!
	#NOTE: i think this will be cleaner if we have a dictionary of the booard with the coords as the key. then you can have packed scenes...
		#which makes it easy to check if soemthing is in a spot.
	#step 1: assign an attack to "attack_one" on main character
	#step 2: configure that resource with the directions and ranges that attack can hit
	#step 3: get your coords of valid target "spots" with Facing.get_target_cells(unit_pos,unit_facing,get_pattern())
	#step 4: iterate through those coords, and apply damage to a unit there if present and valid target
	pass
	## TODO
	## get affected tiles
	#var rotated_attack_pattern: Array[Vector2i] = Tile Pattern . rotate(cardinal_direction)
	#var affected: Array[Actor] = get_actors_in_pattern(pattern) #change this to rotated_attack_pattern when its ready
	
	#if debug: p("Found %d actors to affect..." % affected.size())
	
	## deal damage to anything there
	#for actor in affected:
	#	actor.take_damage(damage)

func get_actors_in_pattern(attack_pattern:Array[Vector2i]) -> Array[Actor]:
	var actors: Array[Actor]
	
	for coord in attack_pattern: ##change this to rotated_attack_pattern 
		var found_actor: Actor = Level.get_actor_at_relative_pos(_actor,coord)
		
		if found_actor != null:
			actors.append(found_actor)
	return actors
