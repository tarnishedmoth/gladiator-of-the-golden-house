class_name PersistentActorData extends Resource

## Snapshot of an Actor's persistent state across level transitions.
## See [method Actor.apply_persistent_data] for the mutation side.
## Saved/loaded via [method to_dict] / [method from_dict] —
## if you add a runtime-mutable field, you MUST update both serialization methods.

var max_health: int
var current_health: int
var starting_energy: int
var status_effects: Array[Status]
var stash: Array[Action]  ## Bonus action cards carried between levels.

var ui_name: String
var ui_subtitle: String
var ui_description: String

## Status/stash dicts whose UID could not be resolved at load time (renamed/deleted .tres).
## Retained verbatim so a subsequent save round-trips them unchanged — lets a temporarily-missing
## asset reconnect on the next load instead of corrupting the user's save.
var _unresolved_statuses: Array = []
var _unresolved_stash: Array = []


func capture_from_actor(actor: Actor) -> void:
	max_health = actor.max_health
	current_health = actor.health
	starting_energy = actor.starting_energy
	capture_status_effects_from(actor)
	ui_name = actor.ui_name
	ui_subtitle = actor.ui_subtitle
	ui_description = actor.ui_description


func capture_status_effects_from(actor: Actor) -> void:
	status_effects = []
	for s in actor.status_effects:
		if s.persist_through_matches:
			## Detach from live status — a turn tick between capture and to_dict() must not
			## mutate the saved snapshot.
			var copy: Status = s.duplicate()
			SaveUid.tag_duplicate(s, copy)
			status_effects.append(copy)


## Serializes to a primitive Dictionary suitable for FileAccess.store_var.
func to_dict() -> Dictionary:
	var status_dicts: Array = []
	for s in status_effects: status_dicts.append(s.to_dict())
	status_dicts.append_array(_unresolved_statuses)  ## Round-trip unresolved entries verbatim.
	var stash_dicts: Array = []
	for a in stash: stash_dicts.append(a.to_dict())
	stash_dicts.append_array(_unresolved_stash)
	return {
		"max_health": max_health,
		"current_health": current_health,
		"starting_energy": starting_energy,
		"ui_name": ui_name,
		"ui_subtitle": ui_subtitle,
		"ui_description": ui_description,
		"status_effects": status_dicts,
		"stash": stash_dicts,
	}


## Reconstructs from a save dict. Entries whose UID can't be resolved are retained in
## `_unresolved_*` so [method to_dict] re-emits them — a missing asset doesn't permanently
## strip the player's save.
static func from_dict(d: Dictionary) -> PersistentActorData:
	var p := PersistentActorData.new()
	p.max_health = d.get("max_health", 0)
	p.current_health = d.get("current_health", 0)
	p.starting_energy = d.get("starting_energy", 0)
	p.ui_name = d.get("ui_name", "")
	p.ui_subtitle = d.get("ui_subtitle", "")
	p.ui_description = d.get("ui_description", "")
	p.status_effects = []
	p._unresolved_statuses = []
	for s_dict in d.get("status_effects", []):
		var s := Status.from_dict(s_dict)
		if s: p.status_effects.append(s)
		else: p._unresolved_statuses.append(s_dict)
	p.stash = []
	p._unresolved_stash = []
	for a_dict in d.get("stash", []):
		var a := Action.from_dict(a_dict)
		if a: p.stash.append(a)
		else: p._unresolved_stash.append(a_dict)
	return p
