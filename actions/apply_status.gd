class_name ActionApplyStatus extends Action

## Sort of DEPRECATED, this class as implemented only applies the status effect to the actor who runs it.
## See [ActionApplyStatusPattern]. Retaining because of actions which use it already.

@export var status: Status
@export_range(0, 99, 1, "or_greater") var override_quantity: int:
	get:
		if not override_quantity:
			if status != null: ## null check
				return status.effect_points
			else:
				return 0 ## should never happen
		else:
			return override_quantity
			
@export_group("Timing")
## How long to wait after playing FX, before dealing damage. Use for VFX/SFX timing.
@export_range(0.1, 6.0, 0.1) var pre_attack_duration: float = 0.1
## How long to wait after running action, before exiting the action and progressing gameplay. Use for VFX/SFX. This stacks with [member ActionQueue.POST_ACTION_AWAIT_TIME].
@export_range(0.0, 6.0, 0.1) var post_attack_duration: float = 0.0

@export_group("Oneshot Sfx", "loose_sfx_")
@export var loose_sfx_stream: AudioStream ## Allows for adding a special sound effect (not typical)

enum LooseSfxTiming {PRE = 0, RUN = 1, POST = 2}
@export var loose_sfx_timing: LooseSfxTiming = LooseSfxTiming.RUN

## On transition to this state
func enter(_from: ResourceState = null) -> void:
	if loose_sfx_stream and loose_sfx_timing == LooseSfxTiming.PRE:
		_actor.play_sfx_loose(loose_sfx_stream)
	
	await _actor.create_tween().tween_interval(pre_attack_duration).finished
	
	if loose_sfx_stream and loose_sfx_timing == LooseSfxTiming.RUN:
		_actor.play_sfx_loose(loose_sfx_stream)
	
	## Actually do the thing
	if status:
		_get_affected_and_apply_status()
	
	if post_attack_duration > 0.0:
		await _actor.create_tween().tween_interval(post_attack_duration).finished
	
	if loose_sfx_stream and loose_sfx_timing == LooseSfxTiming.POST:
		_actor.play_sfx_loose(loose_sfx_stream)
	
	exit()
	
func _get_affected_and_apply_status() -> void:
	var affected_tiles: Array[Vector2i]
	
	if _target != null:
		## New behavior: only the _target tile
		affected_tiles.append(_target)
	else:
		## (Old behavior): Every coord relative to _actor
		## Still utilized by AI Actors for some actions
		affected_tiles = _actor.get_action_target_cells(self)

	if debug: p("Targeting %d tiles." % affected_tiles.size())
	var affected_actors: Array[Actor]
	for coords in affected_tiles:
		var found_actor: Actor = Level.get_actor_at(coords)
		if found_actor:
			affected_actors.append(found_actor)
			
	var tiles_with_actors: Array[Vector2i]
	for actor in affected_actors:
		tiles_with_actors.append(actor.current_tile_coords)
	## Pass in all valid tiles, and all tiles actually about to be affected
	pulse_affected_tiles(affected_tiles, tiles_with_actors) ## VFX
	
	if affected_actors.is_empty():
		if debug: p("None affected.")
		Level.get_hud().popup_label("Missed", _actor, LevelHUD.STYLE_NEGATED)
	
	else:
		for actor in affected_actors:
			apply_status(actor)


## Copies the status effect resource and applies it to the actor.
func apply_status(actor: Actor) -> void:
	if not actor:
		push_error("Actor is invalid")
	else:
		if debug: p("Applying status %s to %s" % [status.ui_name, actor])
		StatusManager.apply_status_to_actor(status, actor, override_quantity)
		
		await actor.animation_finished

func applies_to_actor(_actor_to_apply_status_to: Actor) -> bool: return true
