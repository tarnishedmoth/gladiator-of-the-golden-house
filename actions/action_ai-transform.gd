extends Action

@export var duration: float = 1.0
@export var new_action_set: Array[Action]
@export var new_action_queue_size: int = -1 ## If set to -1, will not change the queue size. Relies on new_action_set being set
@export var play_transform_vfx: bool = true

func enter(_from: ResourceState = null) -> void:
	transform()
	var d: Tween = _actor.create_tween()
	d.tween_interval(duration)
	d.tween_callback(exit)

func transform() -> void:
	if _actor is AIActor:
		if new_action_set:
			_actor.replace_usable_actions(new_action_set, new_action_queue_size)
	if play_transform_vfx:
		_actor.spawn_vfx(ActorVfxHandler.FX.TRANSFORM)
