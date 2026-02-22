class_name ActionRequirementEnergy extends ActionRequirement

@export var quantity: int

func check(actor: Actor) -> bool:
	return actor.energy >= quantity
