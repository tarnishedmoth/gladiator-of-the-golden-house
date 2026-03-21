class_name ActionPreview extends Node

var _actor: Actor
var _action: Action
var _popup_label: Label

func setup(actor:Actor)->void:
	_actor=actor
	
func show_preview_action(action:Action)-> void:
	_action=action
	print("Action Preview Activated.")
	
	if action is ActionAttack:
		var targets: Array[Vector2i] = _actor.get_action_target_cells(action)
		for coords in targets:
			var found_actor: Actor = Level.get_actor_at(coords)
			if found_actor != null:
				var damage: String = str(action.damage)
				_popup_label = Level.get_hud().popup_label_persistent("Damage: " + damage, found_actor, found_actor.DAMAGE_POPUP_COLOR)
		TargetFinder.highlight_targets(targets)
		
	
	if action is ActionApplyStatusPattern:
		var targets: Array[Vector2i] = _actor.get_action_target_cells(action)
		for coords in targets:
			var found_actor: Actor = Level.get_actor_at(coords)
			if found_actor != null:
				var effect_points: String = str(action.override_quantity)
				_popup_label = Level.get_hud().popup_label_persistent(action.status.ui_name+ ": " +effect_points, found_actor, found_actor.STATUS_POPUP_COLOR)
		TargetFinder.highlight_targets(targets)
		return
		
			
	if action is ActionApplyStatus:
		var targets: Array[Vector2i] = _actor.get_action_target_cells(action)
		for coords in targets:
			var found_actor: Actor = Level.get_actor_at(coords)
			if found_actor != null:
				var effect_points: String = str(action.override_quantity)
				_popup_label = Level.get_hud().popup_label_persistent(action.status.ui_name+ ": " +effect_points, found_actor, found_actor.STATUS_POPUP_COLOR)
		TargetFinder.highlight_targets(targets)
		return
	
func hide_preview_action()->void:
	TargetFinder.clear_target_highlights()
	Level.get_hud().clear_popup_persistent_label(_popup_label)
