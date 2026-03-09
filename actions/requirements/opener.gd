class_name ActionRequirementOpener extends ActionRequirement

func check(actor: Actor) -> bool:
	return actor.action_count == 0