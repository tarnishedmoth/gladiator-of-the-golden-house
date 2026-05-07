class_name ActionChangeStance extends Action

@export_file("*.tres") var stance_uid: String ## Path/UID to a Stance...
@export var status_effects: Array[Status] ## Active while active, removed when inactive

## Change stance with this action...

## On transition to this state
func enter(from: ResourceState = null) -> void:
	change_stance(_actor)
	exit()

func change_stance(actor: Actor) -> void:
	if not actor:
		push_error("Actor is invalid")
	elif not actor.director is Player:
		push_error("Director is not a Player!")
	else:
		if debug: p("Changing stance!")
		actor.director.call_deferred("change_stance", stance_uid)
		apply_keyed_status_effects()

func apply_keyed_status_effects() -> void:
	for status in status_effects:
		_actor.add_status(status, stance_uid)
