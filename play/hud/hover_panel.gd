class_name HUDHoverPanel extends PanelContainer

const TEMPLATE_STATUS_EFFECT_BUTTON = preload("uid://g8ol80ukqqcc")

@export var description: RichTextLabel
@export var title: RichTextLabel
@export var key_stats: RichTextLabel
@export var status_effects_flow_container: HFlowContainer

var status_effects_flow_container_items: Array[Control]

func clear_all() -> void:
	for child in status_effects_flow_container_items:
		child.queue_free()
	status_effects_flow_container_items.clear()
		
	title.text = ""
	key_stats.text = ""
	description.text = ""


func populate_using_actor_data(actor: Actor) -> void:
	clear_all()
	
	if actor.ui_name:
		title.text = "[center]"
		title.append_text(TextUtils.bold(actor.ui_name))
		
		var subtitle_text: String = ""
		if actor.ui_subtitle:
			subtitle_text += TextUtils.ital("\n" + actor.ui_subtitle)
		if actor.director is AIDirector:
			if actor.director.allied_with_player:
				## Denote allies
				subtitle_text += "\n[color=green](Ally)[/color]"
			else:
				subtitle_text += "\n[color=red](Adversary)[/color]"
		else:
			subtitle_text += "\n[color=orange](Player)[/color]"
		
		title.append_text(subtitle_text)
	
	if actor.ui_description:
		description.text = actor.ui_description
		
	key_stats.text = "[center]"
	key_stats.append_text("HP: %d / %d" % [actor.health, actor.max_health])
	
	for status: Status in actor.get_status_effects():
		var new_status: TextureButton = TEMPLATE_STATUS_EFFECT_BUTTON.instantiate()
		new_status.tooltip_text = str(status) + ": " + status.ui_description
		new_status.texture_normal = status.ui_icon
		status_effects_flow_container_items.append(new_status)
		status_effects_flow_container.add_child(new_status)
		
