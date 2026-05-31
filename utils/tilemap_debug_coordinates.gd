@tool
extends TileMapLayer

## Tool to render coordinates onscreen, works in editor

@export var show_coordinates_in_editor: bool = false:
	set(v):
		show_coordinates_in_editor = v
		_check()
		
@export var show_coordinates_in_game: bool = false:
	set(v):
		show_coordinates_in_game = v
		_check()

@export var tile_coords_debug_text_settings: LabelSettings: ## Applied to every label rendered. Will default if empty.
	get:
		if not tile_coords_debug_text_settings:
			tile_coords_debug_text_settings = LabelSettings.new()
			tile_coords_debug_text_settings.font_size = 6
		return tile_coords_debug_text_settings

@export var tile_coords_debug_text_offset: Vector2 = Vector2(-12, 20)
var tile_coords_debug_overlay_elements: Array[Node]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_check()

func _check():
	if Engine.is_editor_hint():
		if show_coordinates_in_editor:
			render_tile_coordinates_debug_overlay()
			return
	elif show_coordinates_in_game:
		render_tile_coordinates_debug_overlay()
		return
	clear_render_tile_coordinates_debug_overlay()

func clear_render_tile_coordinates_debug_overlay() -> void:
	for child in tile_coords_debug_overlay_elements:
		child.queue_free()
	tile_coords_debug_overlay_elements.clear()

func render_tile_coordinates_debug_overlay() -> void:
	if not tile_coords_debug_overlay_elements.is_empty():
		clear_render_tile_coordinates_debug_overlay()

	for coords in self.get_used_cells():
		var new_label: Label = Label.new()
		add_child(new_label)

		tile_coords_debug_overlay_elements.push_back(new_label)

		new_label.text = str(coords)
		new_label.top_level = true ## just to be unaffected by overlays and modulation
		new_label.label_settings = tile_coords_debug_text_settings
		new_label.global_position = self.to_global(self.map_to_local(coords)) + tile_coords_debug_text_offset
