extends ActionRequirement

@export var quantity: int

func _init() -> void:
	ui_display_title = UIS.REQ_ENERGY_TITLE
	ui_display_description = UIS.REQ_ENERGY_DESCRIPTION

func check(player_data) -> bool:
	#return player_data.energy >= quantity
	## TODO HACK FIXME
	return true
