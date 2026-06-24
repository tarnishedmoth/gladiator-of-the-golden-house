class_name StatusAffectDamagePoised extends StatusAffectDamage

## After hooked, depending on [member apply_to_success] and the result, applies the debuff.
@export var status_to_apply: Status
@export var apply_on_success: bool = false ## If true, applies on success. Otherwise, on failure.

func on_after_hook(successful: bool = true) -> void:
	if successful == apply_on_success:
		apply_status()
	super(successful)
	
func apply_status():
	if not status_to_apply:
		push_warning("No status to apply was configured")
		return
	if debug: p("Poised status is applying to %s." % _actor)
	_actor.add_status(status_to_apply)
