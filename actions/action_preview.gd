class_name ActionPreview extends Node

## DEPRECATED functionality has been merged into [Actor], thank you!!

var _actor: Actor
var _action: Action
var _popup_labels: Array[Label]

func setup(actor:Actor)->void:
	_actor=actor

func show_preview_action(action:Action)-> void:
	_action=action
	#print("Action Preview Activated.")

	var all: Array[Vector2i] = _actor.get_action_target_cells(_action)
	
	if _action is ActionMove:
		TargetFinder.highlight_targets(all, Targeting.COLORS.GREY, _actor)
		return
	
	var targets: Array[Vector2i]
	var potential: Array[Vector2i]
	for coords in all:
		var found_actor: Actor = Level.get_actor_at(coords)
		
		if found_actor != null:
			targets.append(coords)
			
			if action is ActionAttack:
				var damage: String = str(_action.damage)
				_popup_labels.append(Level.get_hud().popup_label_persistent("Damage: " + damage, found_actor, LevelHUD.STYLE_DAMAGE))
				TargetFinder.highlight_target(coords, Targeting.COLORS.RED, _actor)
				
			elif action is ActionApplyStatus:
				var effect_points: String = str(_action.override_quantity)
				_popup_labels.append(Level.get_hud().popup_label_persistent(_action.status.ui_name+ ": " +effect_points, found_actor, LevelHUD.STYLE_STATUS))
				TargetFinder.highlight_target(coords, Targeting.COLORS.YELLOW, _actor)
				
			elif action is ActionMove:
				TargetFinder.highlight_target(coords, Targeting.COLORS.PINK, _actor)
			
		else:
			potential.append(coords)
	
	TargetFinder.highlight_targets(potential, Targeting.COLORS.PINK, _actor)
	

func hide_preview_action()->void:
	TargetFinder.clear_target_highlights(_actor)
	for popup in _popup_labels:
		if is_instance_valid(popup):
			Level.get_hud().clear_popup_persistent_label(popup)
	_popup_labels.clear()
