extends Node2D

@export var track: Level.PlayMusic

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		match track:
			Level.PlayMusic.TRACK_SHERMAN:
				Main.play_sherman(true)
			Level.PlayMusic.TRACK_VAILLANCOURT:
				Main.play_vaillancourt(true)
			Level.PlayMusic.TRACK_SHERMAN_MARCH:
				Main.play_sherman_march(true)
