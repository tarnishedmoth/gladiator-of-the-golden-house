class_name LevelHUD extends CanvasLayer

@onready var move_button: ButtonWithBlips = %MoveButton

@onready var actions: ButtonWithBlips = %Actions
@onready var attack_lh_button: Button = %AttackLHButton
@onready var attack_rh_button: Button = %AttackRHButton

func _ready() -> void:
	## TEST
	move_button
