class_name ActionsPanel extends PanelContainer

var actions_in_hand: Dictionary[ButtonWithBlips, Action]

@export var actions: VBoxContainer

func clear_all_actions() -> void:
	assert(actions)
	for card in actions_in_hand.keys():
		card.queue_free()
	actions_in_hand.clear()

func populate_actions(hand: Array[Action]) -> void:
	assert(actions)
	clear_all_actions()
	
	for card in hand:
		var new_button: ButtonWithBlips = ButtonWithBlips.new()
		actions.add_child(new_button)
		
		actions_in_hand[new_button] = card
		
		new_button.set_blips(card.energy_cost)
		new_button.text = card.ui_title
