class_name ActionPreview extends Node

var _actor: Actor
var _action: Action
var _popup_labels: Array[Label]

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
				_popup_labels.append(Level.get_hud().popup_label_persistent("Damage: " + damage, found_actor, LevelHUD.STYLE_DAMAGE))
		
		TargetFinder.highlight_targets(targets, Targeting.COLORS.RED)

	if action is ActionApplyStatusPattern:
		var targets: Array[Vector2i] = _actor.get_action_target_cells(action)
		for coords in targets:
			var found_actor: Actor = Level.get_actor_at(coords)
			if found_actor != null:
				var effect_points: String = str(action.override_quantity)
				_popup_labels.append(Level.get_hud().popup_label_persistent(action.status.ui_name+ ": " +effect_points, found_actor, LevelHUD.STYLE_STATUS))
		
		TargetFinder.highlight_targets(targets, Targeting.COLORS.RED)
		return


	if action is ActionApplyStatus:
		var targets: Array[Vector2i] = _actor.get_action_target_cells(action)
		for coords in targets:
			var found_actor: Actor = Level.get_actor_at(coords)
			if found_actor != null:
				var effect_points: String = str(action.override_quantity)
				_popup_labels.append(Level.get_hud().popup_label_persistent(action.status.ui_name+ ": " +effect_points, found_actor, LevelHUD.STYLE_STATUS))
		
		TargetFinder.highlight_targets(targets, Targeting.COLORS.RED)
		return

func hide_preview_action()->void:
	TargetFinder.clear_target_highlights()
	for popup in _popup_labels:
		if is_instance_valid(popup):
			Level.get_hud().clear_popup_persistent_label(popup)
	_popup_labels.clear()
