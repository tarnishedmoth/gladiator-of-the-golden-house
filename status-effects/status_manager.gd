class_name StatusManager

var debug: bool:
	get: return actor.debug
func p(args):
	print_rich("[bgcolor=grey][color=black]", "%s StatusManager: " % actor.name, args)

#class Result:
	#var data

## Persistent references
var actor: Actor

var status_effects: Array[Status]:
	get: return actor.status_effects ## cursed

var level: Level:
	get: return Level.get_instance()

var actors_in_level: Array[Actor]:
	get: return Level.get_all_actors_in_play_order()


## Transient references
var affected_tiles: Array[Vector2i] ## Tiles currently being affected by an Action (only relevant during play turn)
var targets: Array[Actor]

func _init(host_actor: Actor) -> void:
	self.actor = host_actor

#region Reactive methods

func on_turn_start() -> void:
	if debug and not status_effects.is_empty():
		p("Started turn with status effects:" + str(status_effects))
	for status in status_effects:
		status.on_turn_start()
		
func on_turn_end() -> void:
	if debug and not status_effects.is_empty():
		p("Started turn with status effects:" + str(status_effects))
	for status in status_effects:
		status.on_turn_end()

func on_take_damage(damage:int) -> int:
	var new_damage: int = damage
	for status in status_effects:
		new_damage = status.on_take_damage(new_damage)
	return new_damage

## Called after [method on_take_damage].
func on_take_direct_damage(damage:int) -> int:
	var new_damage: int = damage
	for status in status_effects:
		new_damage = status.on_take_direct_damage(new_damage)
	return new_damage

## Happens just before dealing any damage
func on_deal_damage(damage:int) -> int:
	var new_damage: int = damage
	for status in status_effects:
		new_damage = status.on_deal_damage(new_damage)
	return new_damage

## Happens just before dealing direct damage
func on_deal_direct_damage(damage:int) -> int:
	var new_damage: int = damage
	for status in status_effects:
		new_damage = status.on_deal_direct_damage(new_damage)
	return new_damage
	
## Happens just before dealing any damage
func on_damage_dealt(damage:int) -> void:
	for status in status_effects:
		status.on_damage_dealt(damage)

## Happens just before dealing direct damage
func on_direct_damage_dealt(damage:int) -> void:
	for status in status_effects:
		status.on_direct_damage_dealt(damage)

#endregion

#region Status stack

func add_status(status: Status, do_duplicate: bool = true) -> void:
	if status in status_effects: ## FIXME I'm pretty sure this is not working correctly
		var _status = status_effects.find(status)
		_status.add_points(status.effect_points)
		if debug:
			p("Added %d points to status %s." % [status.effect_points, _status.ui_name])
	else:
		var new_status: Status
		if do_duplicate:
			new_status = status.duplicate()
		else:
			new_status = status
			
		new_status.set_actor(actor) #setting self to take status effect
		status_effects.append(new_status)
		if debug:
			p("Added new status %s." % new_status)
	
func remove_status(status: Status) -> void:
	status_effects.erase(status)

#endregion

static func apply_status_to_actor(status: Status, target_actor: Actor, override_quantity: int = 0) -> void:
	var _copy = status.duplicate()
	
	if override_quantity > 0:
		_copy.effect_points = override_quantity
	
	#if debug: p("Applying status %s to %s" % [_copy.ui_name, _target])
	target_actor.add_status(_copy)
