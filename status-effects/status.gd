@abstract class_name Status extends Resource

enum StatusEffectCategory{
	NONE,
	BUFF,
	DEBUFF,
}

const STATUS_CATEGORY_ICONS: Dictionary[StatusEffectCategory, Texture2D] = {
	StatusEffectCategory.NONE: preload("uid://disinbamqthvh"),
	StatusEffectCategory.BUFF: preload("uid://c7ers5ee7squq"),
	StatusEffectCategory.DEBUFF: preload("uid://c7ers5ee7squq"),
}

var _actor: Actor
var status_manager: StatusManager:
	get: return _actor.get_status_manager()
	
enum OnStart {
	NOTHING,
	SUBTRACT_ONE,
	HALVE,
	REMOVE_EFFECT,
}

enum Hook {
	ON_TURN_START,
	ON_TURN_END,
	ON_TAKE_DAMAGE,
	ON_TAKE_DIRECT_DAMAGE,
	ON_DEAL_DAMAGE,
	ON_DEAL_DIRECT_DAMAGE,
	ON_DAMAGE_DEALT,
	ON_DIRECT_DAMAGE_DEALT,
	ON_ACTION_PLAYED, ## TODO
	ON_APPLYING_STATUS,
	ON_STATUS_APPLIED,
}

@export var on_start_behavior: OnStart = OnStart.REMOVE_EFFECT ## Happens when a director's turn begins.
@export var after_hook_behavior: OnStart = OnStart.NOTHING
@export var on_end_behavior: OnStart = OnStart.NOTHING ## Happens when a director's turn ends.
@export var only_react_to_actors_turn_notifs: bool = false ## Affects [member on_start_behavior] and [member on_end_behavior].

@export var effect_points: int 

@export var ui_name: String ## This name is also used as a [member unique_name], for combining statuses when applied.
@export var ui_description: String 
@export var status_effect_category: StatusEffectCategory
@export var ui_icon: Texture2D: ## If left undefined, will use one according to its [member action_category].
	get:
		if ui_icon: return ui_icon
		else: return STATUS_CATEGORY_ICONS.get(status_effect_category)
		
## If true, uses BUFF and DEBUFF sound effects in the [ActorSfxHandler].
## If [member status_effect_category] is None, does not play any sfx.
@export_group("SFX")
@export var use_actor_sfx: bool = true
@export var trigger_sfx_per_effect_point: bool = true
@export var sfx_success: ActorSfxHandler.Sounds = ActorSfxHandler.Sounds.NONE ## e.g. defense fully negated damage
@export var sfx_failure: ActorSfxHandler.Sounds = ActorSfxHandler.Sounds.NONE ## e.g. defense overwhelmed

@export_group("VFX", "vfx_")
@export var vfx_applied: PackedScene ## Spawned when applied to an actor. See [StatusManager].

## To be spawned when the status effect hook is triggered.
## Most statuses should not utilize this at all otherwise visually it could get very cluttered.
## i.e. save this for boss fights or other special things
@export var vfx_hook_triggered: PackedScene

var unique_name: StringName:
	get:
		if not unique_name:
			assert(ui_name, "Status must have a unique name assigned")
			unique_name = ui_name as StringName
		return unique_name
		
static func is_same_status(status_a: Status, status_b: Status) -> bool:
	return status_a.unique_name == status_b.unique_name

#set Actor with Status effect
func set_actor(actor:Actor) -> void:
	self._actor = actor

func _react_to_this_turn_notif() -> bool:
	return (not only_react_to_actors_turn_notifs) or (only_react_to_actors_turn_notifs and _actor in Level.get_current_directors_actors())

func on_turn_start() -> void: ## Call super() if you override
	if _react_to_this_turn_notif():
		match on_start_behavior:
			OnStart.SUBTRACT_ONE:
				subtract_points(1)
			OnStart.HALVE:
				halve_points()
			OnStart.REMOVE_EFFECT:
				remove_effect()
			
func on_turn_end() -> void: ## Call super() if you override
	if _react_to_this_turn_notif():
		match on_end_behavior:
			OnStart.SUBTRACT_ONE:
				subtract_points(1)
			OnStart.HALVE:
				halve_points()
			OnStart.REMOVE_EFFECT:
				remove_effect()
			
func on_after_hook(successful: bool = true) -> void: ## Call super() if you override
	if vfx_hook_triggered and _actor:
		if _actor.vfx:
			_actor.vfx.play_status(vfx_hook_triggered, self)
	
	if successful and sfx_success:
		_actor.play_sfx(sfx_success)
	elif not successful and sfx_failure:
		_actor.play_sfx(sfx_failure)
	
	match after_hook_behavior:
		OnStart.SUBTRACT_ONE:
			subtract_points(1)
		OnStart.HALVE:
			halve_points()
		OnStart.REMOVE_EFFECT:
			remove_effect()

func on_take_damage(damage:int) -> int: ## Override me
	return damage
	
func on_take_direct_damage(damage:int) -> int: ## Override me
	return damage

func on_deal_damage(damage:int) -> int: ## Override me
	return damage
	
func on_deal_direct_damage(damage:int) -> int: ## Override me
	return damage
	
## Called when actor just began applying a new status effect.
func on_applying_status(new_status: Status) -> Status: ## Override me
	return new_status

@warning_ignore("unused_parameter")
## Happens after damage has been dealt by the actor with this status. The value can not be manipulated. Override me.
func on_damage_dealt(damage:int) -> void:
	pass

@warning_ignore("unused_parameter")
## Happens after damage has been dealt by the actor with this status. The value can not be manipulated. Override me.
func on_direct_damage_dealt(damage:int) -> void:
	pass
	
@warning_ignore("unused_parameter")
## Happens after some other status has been applied to the actor with this status.
func on_status_applied(new_status: Status) -> void:
	pass
	#if not is_same_status(self, new_status): #on_after_hook() ## Must be invoked by an extension
		#on_after_hook()

# what do we need to really know about for all possible status effects
# -the actor holding this status effect
# -the actor being targeted by some action
# -all actors in the level -- via Level static instance
# -the tile we're standing on, the tiles in the arena -- via Level static instance

## Common behaviors
func remove_if_empty() -> void:
	if effect_points <= 0:
		remove_effect()

func remove_effect() -> void:
	_actor.remove_status(self)
	
func subtract_points(i: int, and_remove: bool = true) -> void:
	effect_points -= i
	if and_remove:
		remove_if_empty()
		
func add_points(i: int) -> void:
	effect_points += i

func halve_points() -> void:
	if effect_points > 1:
		effect_points = ceili(float(effect_points) / 2.0)
	## If 1, leave it unchanged.
	## If 0 or below, leave it unchanged.

func _to_string() -> String:
	var format: String = "%s" % ui_name if ui_name else "NONAME"
	if effect_points != 0:
		format += "(%d)" % effect_points
	return format


#region Save / Load

## Mutable runtime state worth saving: `effect_points`. Other fields come from the .tres.
## If you add a mutable field to Status, update to_dict/from_dict.
func to_dict() -> Dictionary:
	var uid_text := SaveUid.resolve(self)
	assert(uid_text != "", "Status %s has no UID — must originate from a .tres asset (resource_path=%s)." % [self, resource_path])
	return {
		"uid": uid_text,
		"effect_points": effect_points,
	}

## Reconstructs a detached Status instance from a save dict. Returns null on UID-load failure
## (renamed/deleted .tres) — callers should retain the original dict to round-trip unresolved entries.
static func from_dict(d: Dictionary) -> Status:
	var uid_text: String = d.get("uid", "")
	if uid_text == "":
		push_warning("Status.from_dict: missing 'uid' key")
		return null
	var uid_id := ResourceUID.text_to_id(uid_text)
	if uid_id == ResourceUID.INVALID_ID or not ResourceUID.has_id(uid_id):
		push_warning("Status.from_dict: unresolvable UID %s" % uid_text)
		return null
	var template := load(ResourceUID.get_id_path(uid_id)) as Status
	if not template:
		push_warning("Status.from_dict: failed to load %s" % uid_text)
		return null
	var instance := template.duplicate(true) as Status
	SaveUid.tag_duplicate(template, instance)
	instance.effect_points = d.get("effect_points", 0)
	return instance

#endregion
