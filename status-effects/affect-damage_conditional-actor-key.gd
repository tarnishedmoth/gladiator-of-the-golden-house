class_name StatusAffectDamageConditional extends Status

## Check for actors, either using a target key or simply counting the team members.
## If threshold reached, applies the effect (multiplying incoming damage by [member factor]).

enum Modes {
	TEAM_COUNT = 0, ## Count the actors sharing the same director as this actor (not including).
	USE_KEY = 1, ## Count the actors with this persistent data key.
}

@export var mode: Modes

@export var threshold: int = 1 ## Found actors must meet or exceed this value.

## If true, effect applies when condition is not met. Otherwise, when it is met (normal behavior).
@export var invert_conditional: bool = false

@export var factor: float = 0.25 ## Multiplier to damage when conditionally true.
@export var per_actor_found: bool = false ## Multiplies
@export var direct_only: bool = false ## Only applies to direct damage.

@export_group("Use Key")
@export var target_key: StringName ## If set, looks for an [Actor] with a matching [member Actor.persistent_data_key].

## If true, only requires the [member target_key] to be present *within* the actor's [member Actor.persistent_data_key].
## Otherwise, the keys must match exactly.
@export var use_substring: bool = true

func get_damage(damage: int) -> int:
	var found: int = 0
	
	var condition_met: bool = false
	
	match mode:
		Modes.TEAM_COUNT:
			assert(_actor, "_actor wasn't configured for status effect")
			if _actor:
				found = _actor.director.actors.size() - 1
				if found < 1:
					p("No actors found on team.")
			
		Modes.USE_KEY:
			var is_valid: bool = target_key != null
			assert(is_valid, "Empty target key for check.")
			if is_valid:
				
				for a in Level.get_all_actors_in_play_order():
					
					if not use_substring:
						if a.persistent_data_key == target_key:
							found += 1
					
					else:
						if a.persistent_data_key.contains(target_key):
							found += 1
						
			if found < 1:
				p("No actors found matching key %s." % target_key if not use_substring else ("*" + target_key + "*"))
	
	if found >= threshold:
		condition_met = true
	else:
		condition_met = false
		p("Threshold not reached to apply conditional damage multiplier.")
	
	if invert_conditional:
		condition_met = not condition_met
	
	if not condition_met:
		p("Condition not met to apply conditional damage multiplier.")
		return damage
	
	else:
		var damage_to_take := float(damage)
		
		for x in found if per_actor_found else 1:
			damage_to_take *= factor
		
		p("Incoming damage affected by %d found actors (%d orig, %f new)" % [damage, damage_to_take])
		return ceili(damage_to_take)


func on_take_damage(damage: int) -> int: ## Override me
	if direct_only:
		return damage
	
	damage = get_damage(damage)
	on_after_hook()
	return damage

func on_take_direct_damage(damage: int) -> int: ## Override me
	if not direct_only:
		return damage
	
	damage = get_damage(damage)
	on_after_hook()
	return damage
