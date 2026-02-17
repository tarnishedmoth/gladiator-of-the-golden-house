class_name LevelHUD extends CanvasLayer

@onready var hover_panel: HUDHoverPanel = %HoverPanel

@onready var actions: VBoxContainer = %Actions

func _ready() -> void:
	hover_panel.modulate = Color.TRANSPARENT

func show_hover_panel(show_:bool = true) -> void:
	if not show_:
		Juice.fade_out(hover_panel)
	else:
		Juice.advanced_fade(hover_panel, Juice.SMOOTH, Color.WHITE)

func populate_hover_panel(tile_coords: Vector2i, actor: Actor) -> void:
	## Replace tile_coords with TileData or whatever more complex object if we need to.
	if actor:
		hover_panel.populate_using_actor_data(actor)
	else:
		hover_panel.clear_all()
		hover_panel.title.text = "[center]" + str(tile_coords)
