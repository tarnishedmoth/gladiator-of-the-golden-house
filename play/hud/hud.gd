class_name LevelHUD extends CanvasLayer

@onready var hover_panel: PanelContainer = %HoverPanel

@onready var actions: VBoxContainer = %Actions

func _ready() -> void:
	hover_panel.modulate = Color.TRANSPARENT

func show_hover_panel(show_:bool = true) -> void:
	if (not show_):
		Juice.fade_out(hover_panel)
	elif show_:
		#Juice.fade_in(hover_panel)
		Juice.advanced_fade(hover_panel, Juice.SMOOTH, Color.WHITE)
