class_name HUDSelectedActorActionPanel extends PanelContainer

@export var title: RichTextLabel
@export var action_image: TextureRect
@export var description: RichTextLabel
@export var amount: RichTextLabel

var highlight_rect: ColorRect

func _init() -> void:
	if not highlight_rect:
		highlight_rect = ColorRect.new()
		highlight_rect.self_modulate = Color("ffffff28")
		add_child(highlight_rect)

func clear_all() -> void:
	title.text = ""
	description.text = ""
	action_image.texture = null
	amount.text = "[center]"
	amount.hide()
	highlight_rect.hide()

func populate(actor: Actor, action:Action) -> void:
	clear_all()
	if action == null: return
	if action.ui_title:
		title.text = "[center]"
		title.append_text(TextUtils.bold(action.ui_title))
	
	if action.ui_icon:
		action_image.texture = action.ui_icon
		
	if action is ActionAttack:
		amount.append_text("Base Dmg: %d " % [action.damage])
		if action.multiple_attacks > 1:
			amount.append_text("\nx %d times" % action.multiple_attacks)
		amount.show()
		
	if action is ActionAttackKnockback or action is ActionMoveKnockback:
		amount.append_text(("\n" if amount.text.is_empty() else "") + "+Knockback")
		amount.show()
	
	var _description: String = actor.ui_name + " plans to "
	if action.ui_description:
		var first_letter = action.ui_description[0]
		_description = _description + first_letter.to_lower() + action.ui_description.trim_prefix(first_letter)
	else:
		if action is ActionAttack:
			_description = _description + "deal %d damage" % [action.damage]
			if action.multiple_attacks:
				_description += " %d times." % action.multiple_attacks
			else:
				_description += "."
		
		elif action is ActionMove:
			_description = _description + "move."
		elif action is ActionApplyStatus:
			if action.override_quantity:
				_description = _description + " apply %d %s." % [action.override_quantity, action.status]
			else:
				_description = _description + " apply %s." % action.status
	description.text = _description

var _highlighting: Tween
func highlight(yes: bool = true) -> void:
	if _highlighting:
		_highlighting.kill()
	if yes:
		highlight_rect.show()
		_highlighting = highlight_rect.create_tween().set_loops()
		_highlighting.tween_property(highlight_rect, ^"modulate", modulate.darkened(0.75), Juice.FAST)
		_highlighting.tween_property(highlight_rect, ^"modulate", modulate, Juice.FAST)
	else:
		highlight_rect.modulate = Color.WHITE
		highlight_rect.hide()
