class_name HUDActionHoverPanel extends PanelContainer

@export var title: RichTextLabel
@export var action_image: TextureRect
@export var description: RichTextLabel
@export var energy_cost: RichTextLabel
@export var amount_text: RichTextLabel



func clear_all() -> void:
	title.text = ""
	energy_cost.text = ""
	description.text = ""
	amount_text.text = ""
	action_image.texture = null

func populate_using_action_data(action:Action)->void:
	clear_all()
	if action.ui_title:
		title.text = "[center]"
		title.append_text(TextUtils.bold(action.ui_title))
	
	if action.ui_description:
		#description.text = "[center]"
		description.text = action.ui_description
	
	if action.ui_icon:
		action_image.texture = action.ui_icon
	
	if action.energy_cost > 0:
		energy_cost.text = "[center]"
		energy_cost.append_text("EC: %d " % [action.energy_cost])

	if action is ActionAttack:
		amount_text.text = "[center]"
		amount_text.append_text("Damage: %d " % [action.damage])
	
	if action is ActionApplyStatus:
		amount_text.text = "[center]"
		if action.status:
			amount_text.append_text("Amount: %d" % [action.status.effect_points])
		
