class_name SaveLoadTestHelper extends CanvasLayer

## Root script of save_load_test_overlay.tscn. Attach the overlay to any test level
## containing a Player director with persistent_data_key set, to verify save/load end-to-end:
##  - Frozen "saved state" view of PlayerData.persistent_actors
##  - Live actor state with green/red diff against saved
##  - Buttons to mutate state (damage, statuses, stash, pickup) without combat
##  - Save Slot 99 + Reload exercises the full disk → load → apply pipeline

const TEST_BLEED = preload("uid://dth73y4ujmctl")  ## status-effects/prefabs/bleed.tres
const TEST_DEFENSE = preload("uid://yrjd3nv2uamc")  ## status-effects/prefabs/defense.tres
const TEST_STASH_ACTION = preload("uid://cja0r0w64c03i")  ## actions/prefabs/basic_attack_one_tile_front.tres
const TEST_SAVE_SLOT: int = 99  ## Out-of-band slot number to avoid clobbering real save slots.

@onready var phase_label: Label = %PhaseLabel
@onready var comparison_label: RichTextLabel = %ComparisonLabel
@onready var slot_warn_label: Label = %SlotWarnLabel
@onready var btn_damage: Button = %BtnDamage
@onready var btn_bleed: Button = %BtnBleed
@onready var btn_defense: Button = %BtnDefense
@onready var btn_stash: Button = %BtnStash
@onready var btn_pickup: Button = %BtnPickup
@onready var btn_save_reload: Button = %BtnSaveReload

var player_actor: Actor
var player_director: Player
var _player_freed_handled: bool = false


func _ready() -> void:
	slot_warn_label.text = "⚠ Save+Reload overwrites slot %d (.save and .save.old)" % TEST_SAVE_SLOT
	btn_save_reload.text = "Save Slot %d + Reload Scene" % TEST_SAVE_SLOT
	btn_damage.pressed.connect(_on_damage_pressed)
	btn_bleed.pressed.connect(_on_apply_bleed_pressed)
	btn_defense.pressed.connect(_on_apply_defense_pressed)
	btn_stash.pressed.connect(_on_add_stash_pressed)
	btn_pickup.pressed.connect(_on_trigger_pickup_pressed)
	btn_save_reload.pressed.connect(_on_save_reload_pressed)

	## Wait two frames for Level.start_game.call_deferred to wire directors and actors.
	await get_tree().process_frame
	await get_tree().process_frame
	_resolve_player()
	set_process(true)


func _process(_delta: float) -> void:
	if not player_actor or not is_instance_valid(player_actor):
		if not _player_freed_handled:
			phase_label.text = "(actor freed — relaunch the scene)"
			comparison_label.text = ""
			_player_freed_handled = true
		return
	_refresh_comparison()


func _resolve_player() -> void:
	for d in Level.get_directors():
		if d is Player:
			player_director = d
			player_actor = d.actors.front()
			return
	push_error("SaveLoadTestHelper: no Player director found in level.")


func _refresh_comparison() -> void:
	var has_persisted: bool = (PlayerData.this != null
		and player_actor.persistent_data_key in PlayerData.this.persistent_actors)
	phase_label.text = "Phase: AFTER LOAD" if has_persisted else "Phase: BEFORE SAVE"

	var saved: PersistentActorData = (PlayerData.get_actor_data(player_actor.persistent_data_key)
		if has_persisted else null)
	var live_status_strs := _format_status_array(player_actor.status_effects)
	var live_stash_count: int = player_director.stash.size() if player_director else 0

	var lines: PackedStringArray = []
	lines.append("[b]Field   |  Saved  →  Live[/b]")
	if saved:
		lines.append(_diff_line("HP", "%d/%d" % [saved.current_health, saved.max_health], "%d/%d" % [player_actor.health, player_actor.max_health]))
		lines.append(_diff_line_status(_format_status_array(saved.status_effects), live_status_strs))
		lines.append(_diff_line("Stash", str(saved.stash.size()), str(live_stash_count)))
	else:
		lines.append("[i](no saved data; click Save+Reload to capture)[/i]")
		lines.append("Live HP: %d/%d" % [player_actor.health, player_actor.max_health])
		lines.append("Live Status: %s" % (", ".join(live_status_strs) if live_status_strs.size() > 0 else "(none)"))
		lines.append("Live Stash: %d" % live_stash_count)
	comparison_label.text = "\n".join(lines)


## Returns a BBCode-coloured row: green if saved == live; red otherwise.
func _diff_line(label: String, saved_val: String, live_val: String) -> String:
	if saved_val == live_val:
		return "[color=green]%s: %s[/color]" % [label, saved_val]
	return "[color=red]%s: saved=%s ≠ live=%s[/color]" % [label, saved_val, live_val]


## Status diff is more nuanced: Bleed has SUBTRACT_ONE on turn start, so live=saved-1 is expected.
## If every entry's name still matches in order, treat as a benign post-tick drift (yellow).
func _diff_line_status(saved_strs: PackedStringArray, live_strs: PackedStringArray) -> String:
	var saved_text := ", ".join(saved_strs) if saved_strs.size() > 0 else "(none)"
	var live_text := ", ".join(live_strs) if live_strs.size() > 0 else "(none)"
	if saved_text == live_text:
		return "[color=green]Status: %s[/color]" % saved_text
	if _is_post_tick_drift(saved_strs, live_strs):
		return "[color=yellow]Status (post-tick): %s → %s[/color]" % [saved_text, live_text]
	return "[color=red]Status: saved=%s ≠ live=%s[/color]" % [saved_text, live_text]


func _is_post_tick_drift(saved_strs: PackedStringArray, live_strs: PackedStringArray) -> bool:
	if saved_strs.size() < live_strs.size(): return false
	var n := mini(saved_strs.size(), live_strs.size())
	for i in range(n):
		if saved_strs[i].split("(")[0] != live_strs[i].split("(")[0]:
			return false
	return true


func _format_status_array(arr: Array[Status]) -> PackedStringArray:
	var out: PackedStringArray = []
	for s in arr:
		out.append("%s(%d)" % [s.ui_name, s.effect_points])
	return out


func _on_damage_pressed() -> void:
	if not player_actor: return
	player_actor.take_direct_damage(30)


func _on_apply_bleed_pressed() -> void:
	if not player_actor: return
	StatusManager.apply_status_to_actor(TEST_BLEED, player_actor, 3)


func _on_apply_defense_pressed() -> void:
	if not player_actor: return
	StatusManager.apply_status_to_actor(TEST_DEFENSE, player_actor, 3)


func _on_add_stash_pressed() -> void:
	if not player_director: return
	var card: Action = TEST_STASH_ACTION.duplicate()
	SaveUid.tag_duplicate(TEST_STASH_ACTION, card)
	player_director.add_to_stash(card)


## Triggers the nearest pickup as if the player walked over it.
## Exercises the real PickUp.on_pick_up → Player.add_to_stash path.
func _on_trigger_pickup_pressed() -> void:
	if not player_actor: return
	var pickups := Level.get_all_pick_ups()
	if pickups.is_empty():
		push_warning("No pickup in level to trigger.")
		return
	pickups[0].on_pick_up(player_actor)


## Pushes live state into PlayerData, writes to slot 99, reads it back, reloads scene.
##
## Uses Main.reload_current_scene (not the engine's get_tree().reload_current_scene),
## because this project nests scenes as children of Main.tscn rather than swapping the
## tree's "current scene" — the engine reload would land back at the dev menu.
func _on_save_reload_pressed() -> void:
	Level.get_instance().save_persistent_actors_data()
	SaveLoad.save_game(TEST_SAVE_SLOT)
	SaveLoad.load_game(SaveLoad.get_filepath_for_slot(TEST_SAVE_SLOT))
	Main.reload_current_scene()
