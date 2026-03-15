class_name HUDSelectedActorActionPanel extends PanelContainer

@export var title: RichTextLabel
@export var action_image: TextureRect
@export var description: RichTextLabel



func clear_all() -> void:
	title.text = ""
	description.text = ""
	action_image.texture = null

func populate(actor: Actor, action:Action) -> void:
	clear_all()
	if action.ui_title:
		title.text = "[center]"
		title.append_text(TextUtils.bold(action.ui_title))
	
	if action.ui_icon:
		action_image.texture = action.ui_icon
	
	var _description: String = actor.ui_name + " plans to "
	if action.ui_description:
		var first_letter = action.ui_description[0]
		_description = _description + first_letter.to_lower() + action.ui_description.trim_prefix(first_letter)
	else:
		if action is ActionAttack:
			_description = _description + "deal %d damage." % [action.damage]
		elif action is ActionMove:
			_description = _description + "move."
		elif action is ActionApplyStatus:
			if action.override_quantity:
				_description = _description + " apply %d %s." % [action.override_quantity, action.status]
			else:
				_description = _description + " apply %s." % action.status
	description.text = _description
