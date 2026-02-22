class_name LevelHUD extends CanvasLayer

#static var instance: LevelHUD:
	#set(v):
		#if (v != null) and (instance != null):
			#assert(not is_instance_valid(instance), "More than one instance in memory")
		#instance = v

@onready var hover_panel: HUDHoverPanel = %HoverPanel
@onready var actions_panel: ActionsPanel = %ActionsPanel

#func _enter_tree() -> void:
	#instance = self
	#
#func _exit_tree() -> void:
	#if instance == self: instance = null

func _ready() -> void:
	## Setup
	hover_panel.modulate = Color.TRANSPARENT
	actions_panel.action_button_pressed.connect(_on_action_pressed)

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

## Action Panel signals
func _on_action_pressed(action: Action) -> void:
	var player = Level.get_instance().get_current_director()
	assert(player is Player)
	if player is Player:
		player.hold_action(action)

func populate_actions_list(hand: Array[Action]) -> void:
	actions_panel.populate_actions(hand)
