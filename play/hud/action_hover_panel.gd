class_name HUDActionHoverPanel extends PanelContainer

const SCROLL_SPEED: int = 6

@export var title: RichTextLabel
@export var action_image: TextureRect
@export var category: RichTextLabel
@export var description: RichTextLabel
@export var energy_cost: RichTextLabel
@export var amount_text: RichTextLabel

func _unhandled_input(event: InputEvent) -> void:
	if visible:
		if event.is_action(&"scroll_down"):
			scroll_description(true)
		elif event.is_action(&"scroll_up"):
			scroll_description(false)
		
func scroll_description(down: bool) -> void:
	description.get_v_scroll_bar().value += SCROLL_SPEED if down else -SCROLL_SPEED

func clear_all() -> void:
	title.text = ""
	category.text = ""
	energy_cost.text = ""
	description.text = ""
	amount_text.text = ""
	action_image.texture = null

func populate_using_action_data(action:Action)->void:
	clear_all()
	if not action:
		push_warning("Null action provided.")
		return
	
	if action.ui_title:
		title.text = "[center]"
		title.append_text(TextUtils.bold(action.ui_title))
	
	category.text = action.ui_category
	
	
	## Description
	#description.text = "[center]"
	var _description_text = ""
	if action.allow_facing_before:
		_description_text += "Change facing direction before.\n"
	if action.ui_description:
		_description_text += action.ui_description
	if action.allow_facing_after:
		_description_text += "\nChange facing direction after."
	
	if action is ActionChangeStance:
		if not _description_text.is_empty():
			_description_text += "\n\n"
		_description_text += "Actions:\n"
		## Append the actions in this stance.
		var stance: Stance = ResourceLoader.load(ResourceUID.uid_to_path(action.stance_uid))
		var i: int = 0
		for _action in stance.actions:
			_description_text += TextUtils.ital(("\n" if i > 0 else "") + _action.ui_title)
			i += 1
	
	description.text = _description_text
	
	if action.ui_icon:
		action_image.texture = action.ui_icon
	
	if action.energy_cost > 0:
		energy_cost.text = "[center]"
		energy_cost.append_text("EC: %d " % [action.energy_cost])

	if action is ActionAttack:
		amount_text.text = "[center]"
		amount_text.append_text("Damage: %d " % [action.damage])
	
	if action is ActionApplyStatus:
		if action.status:
			amount_text.text = "[center]"
			if action.status.effect_points:
				amount_text.append_text("Amount: %d" % [action.status.effect_points])
			
			description.append_text("\n" + \
				action.status.ui_name + ":\n" + \
				TextUtils.ital(action.status.ui_description)
				)
		
