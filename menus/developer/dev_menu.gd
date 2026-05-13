class_name DeveloperMainMenu extends Control

const _ROUNDTRIP_TEST_BLEED = preload("uid://dth73y4ujmctl")  ## bleed.tres
const _ROUNDTRIP_TEST_DEFENSE = preload("uid://yrjd3nv2uamc")  ## defense.tres
const _ROUNDTRIP_TEST_ATTACK = preload("uid://cja0r0w64c03i")  ## basic_attack_one_tile_front.tres
const _ROUNDTRIP_TEST_MOVE = preload("uid://jw3r4whhtbxs")  ## move_one_tile.tres

@export var selectable_levels: Array[PackedScene]

@onready var select_dropdown: OptionButton = %SelectDropdown

@onready var bg: ColorRect = %BG
@onready var contents: VBoxContainer = %Contents

func _ready() -> void:
	var id:int = 1 # 0 is reserved for divider.
	for level in selectable_levels:
		if level is PackedScene:
			# Valid array entry
			select_dropdown.add_item(level.resource_path.trim_prefix("res://"), id) # Display text
			select_dropdown.set_item_metadata(id, level.resource_path) # Filepath
			id += 1

	Juice.fade_in(contents, Juice.PATIENT, Color.TRANSPARENT)


func _on_launch_button_pressed() -> void:
	## Preset the persistent player data for proper functionality
	PlayerData.new_playthrough("Developer", PlayerData.STARTING_CLASSES.CLASSIC) ## TESTING

	var resource:PackedScene = load(select_dropdown.get_item_metadata(select_dropdown.selected))

	# Visual effect
	var exit:Tween = Juice.fade_out(bg, Juice.SNAPPY, Color.BLACK)
	await exit.finished

	# Action
	Main.change_scene(resource)


## Round-trips hand-crafted PersistentActorData through to_dict()/from_dict() and verifies equality.
## Catches Resource serialization regressions in <1s, without playing through a level.
##
## Uses push_error (not assert) so it remains effective in release builds — assert() is stripped.
##
## Catches: serialization regressions (dropped fields, broken UID round-trip,
## missing-UID handling, empty-array degenerate cases, multi-entry ordering).
## Does NOT catch: disk I/O, apply_persistent_data side effects, level lifecycle.
## For those, use the test-save-load scene.
func _on_roundtrip_button_pressed() -> void:
	var ok := true
	ok = _roundtrip_case_basic() and ok
	ok = _roundtrip_case_empty_arrays() and ok
	ok = _roundtrip_case_multi_status() and ok
	ok = _roundtrip_case_multi_stash() and ok
	ok = _roundtrip_case_zero_effect_points() and ok
	ok = _roundtrip_case_max_below_current() and ok
	ok = _roundtrip_case_missing_uid() and ok
	if ok:
		print_rich("[color=green]Round-trip assertion PASSED.")
	else:
		print_rich("[color=red]Round-trip assertion FAILED — see push_error output above.")


## Field-equality check; logs a push_error on mismatch. Returns ok-status for chaining.
func _check(label: String, actual, expected) -> bool:
	if actual != expected:
		push_error("Round-trip: %s mismatch (got %s, expected %s)" % [label, actual, expected])
		return false
	return true


## Basic round-trip: typical state with HP, energy, UI strings, one status, one stash card.
func _roundtrip_case_basic() -> bool:
	var original := PersistentActorData.new()
	original.max_health = 100
	original.current_health = 42
	original.starting_energy = 7
	original.ui_name = "RoundTripTester"
	original.ui_subtitle = "subtitle"
	original.ui_description = "desc"
	var bleed := _ROUNDTRIP_TEST_BLEED.duplicate(true) as Status
	SaveUid.tag_duplicate(_ROUNDTRIP_TEST_BLEED, bleed)
	bleed.effect_points = 7
	original.status_effects = [bleed]
	original.stash = [_ROUNDTRIP_TEST_ATTACK]

	var restored := PersistentActorData.from_dict(original.to_dict())
	var ok := true
	ok = _check("basic.max_health", restored.max_health, 100) and ok
	ok = _check("basic.current_health", restored.current_health, 42) and ok
	ok = _check("basic.starting_energy", restored.starting_energy, 7) and ok
	ok = _check("basic.ui_name", restored.ui_name, "RoundTripTester") and ok
	ok = _check("basic.ui_subtitle", restored.ui_subtitle, "subtitle") and ok
	ok = _check("basic.ui_description", restored.ui_description, "desc") and ok
	ok = _check("basic.status_effects.size", restored.status_effects.size(), 1) and ok
	if restored.status_effects.size() == 1:
		ok = _check("basic.status_effects[0].effect_points", restored.status_effects[0].effect_points, 7) and ok
		ok = _check("basic.status_effects[0].unique_name", restored.status_effects[0].unique_name, _ROUNDTRIP_TEST_BLEED.unique_name) and ok
	ok = _check("basic.stash.size", restored.stash.size(), 1) and ok
	if restored.stash.size() == 1:
		ok = _check("basic.stash[0].uid", SaveUid.resolve(restored.stash[0]), SaveUid.resolve(_ROUNDTRIP_TEST_ATTACK)) and ok
	return ok


## Empty-arrays case: no statuses, no stash. Verifies the iteration paths handle len-0 correctly.
func _roundtrip_case_empty_arrays() -> bool:
	var original := PersistentActorData.new()
	original.max_health = 50
	original.current_health = 50
	original.status_effects = []
	original.stash = []
	var restored := PersistentActorData.from_dict(original.to_dict())
	var ok := true
	ok = _check("empty.status_effects.size", restored.status_effects.size(), 0) and ok
	ok = _check("empty.stash.size", restored.stash.size(), 0) and ok
	return ok


## Multi-status case: insertion order preserved, both entries' effect_points round-trip.
func _roundtrip_case_multi_status() -> bool:
	var bleed := _ROUNDTRIP_TEST_BLEED.duplicate(true) as Status
	SaveUid.tag_duplicate(_ROUNDTRIP_TEST_BLEED, bleed)
	bleed.effect_points = 7
	var defense := _ROUNDTRIP_TEST_DEFENSE.duplicate(true) as Status
	SaveUid.tag_duplicate(_ROUNDTRIP_TEST_DEFENSE, defense)
	defense.effect_points = 3

	var original := PersistentActorData.new()
	original.status_effects = [bleed, defense]

	var restored := PersistentActorData.from_dict(original.to_dict())
	var ok := true
	ok = _check("multi_status.size", restored.status_effects.size(), 2) and ok
	if restored.status_effects.size() == 2:
		ok = _check("multi_status[0].unique_name", restored.status_effects[0].unique_name, _ROUNDTRIP_TEST_BLEED.unique_name) and ok
		ok = _check("multi_status[0].effect_points", restored.status_effects[0].effect_points, 7) and ok
		ok = _check("multi_status[1].unique_name", restored.status_effects[1].unique_name, _ROUNDTRIP_TEST_DEFENSE.unique_name) and ok
		ok = _check("multi_status[1].effect_points", restored.status_effects[1].effect_points, 3) and ok
	return ok


## Multi-stash case: two different actions, order preserved, both UIDs match.
func _roundtrip_case_multi_stash() -> bool:
	var original := PersistentActorData.new()
	original.stash = [_ROUNDTRIP_TEST_ATTACK, _ROUNDTRIP_TEST_MOVE]
	var restored := PersistentActorData.from_dict(original.to_dict())
	var ok := true
	ok = _check("multi_stash.size", restored.stash.size(), 2) and ok
	if restored.stash.size() == 2:
		ok = _check("multi_stash[0].uid", SaveUid.resolve(restored.stash[0]), SaveUid.resolve(_ROUNDTRIP_TEST_ATTACK)) and ok
		ok = _check("multi_stash[1].uid", SaveUid.resolve(restored.stash[1]), SaveUid.resolve(_ROUNDTRIP_TEST_MOVE)) and ok
	return ok


## Status with effect_points=0 case: capture-time should filter, but a hand-crafted dict
## with effect_points=0 should round-trip to a Status with that exact value (no clamping in serialization).
func _roundtrip_case_zero_effect_points() -> bool:
	## Skip the capture-side filter by hand-crafting a dict directly.
	var fake_dict := {
		"max_health": 50,
		"current_health": 50,
		"starting_energy": 0,
		"ui_name": "",
		"ui_subtitle": "",
		"ui_description": "",
		"status_effects": [{ "uid": SaveUid.resolve(_ROUNDTRIP_TEST_BLEED), "effect_points": 0 }],
		"stash": [],
	}
	var restored := PersistentActorData.from_dict(fake_dict)
	var ok := true
	ok = _check("zero_effect.size", restored.status_effects.size(), 1) and ok
	if restored.status_effects.size() == 1:
		ok = _check("zero_effect.effect_points", restored.status_effects[0].effect_points, 0) and ok
	return ok


## max_health < current_health: serialization preserves both values exactly without clamping.
func _roundtrip_case_max_below_current() -> bool:
	var original := PersistentActorData.new()
	original.max_health = 50
	original.current_health = 80  ## Over-capped
	var restored := PersistentActorData.from_dict(original.to_dict())
	var ok := true
	ok = _check("max_below_current.max_health", restored.max_health, 50) and ok
	ok = _check("max_below_current.current_health", restored.current_health, 80) and ok
	return ok


## Missing-UID case: a saved status whose .tres no longer exists.
## Status.from_dict returns null; PersistentActorData.from_dict retains the dict in
## _unresolved_statuses so the next save round-trips it without losing it.
func _roundtrip_case_missing_uid() -> bool:
	var fake_status := { "uid": "uid://nonexistent_xxxxxxxx", "effect_points": 5 }
	var fake_action := { "uid": "uid://nonexistent_yyyyyyyy" }
	var fake_dict := {
		"max_health": 50,
		"current_health": 50,
		"starting_energy": 0,
		"ui_name": "",
		"ui_subtitle": "",
		"ui_description": "",
		"status_effects": [fake_status],
		"stash": [fake_action],
	}
	var restored := PersistentActorData.from_dict(fake_dict)
	var ok := true
	ok = _check("missing_uid.status_effects.size", restored.status_effects.size(), 0) and ok
	ok = _check("missing_uid._unresolved_statuses.size", restored._unresolved_statuses.size(), 1) and ok
	ok = _check("missing_uid.stash.size", restored.stash.size(), 0) and ok
	ok = _check("missing_uid._unresolved_stash.size", restored._unresolved_stash.size(), 1) and ok
	## And re-serialization should round-trip the unresolved entries verbatim.
	var redumped := restored.to_dict()
	ok = _check("missing_uid.redump_status_count", redumped["status_effects"].size(), 1) and ok
	ok = _check("missing_uid.redump_stash_count", redumped["stash"].size(), 1) and ok
	return ok
