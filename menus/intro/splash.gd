class_name SplashMenu extends Node

signal finished

@onready var ui: Control = $UI
@onready var bg := %BG
@onready var studio: Sprite2D = %Studio
@onready var title := %Title
@onready var version := %Version
@onready var subtext := %Subtext

func _ready() -> void:
	version.text = "v" + Main.get_project_version()
	await animate()
	finished.emit()

func animate() -> void:
	Juice.fade_in(ui, Juice.SLOW)
	var up_tween: Tween = create_tween()
	up_tween.tween_property(studio, "position", studio.position + Vector2.UP * 60.0, 8.0).set_ease(Tween.EASE_IN)
	
	version.modulate = Color.TRANSPARENT
	Juice.fade_in(studio)
	await Juice.fade_in(title, Juice.PATIENT).finished
	await Juice.fade_in(version, Juice.SMOOTH).finished
	await Juice.flash(version, [0.22, 0.66]).finished
	
	Juice.fade_out(studio)
	Juice.fade_out(title)
	Juice.fade_out(subtext)
	Juice.fade_out(version)
	await Juice.fade_out(ui, Juice.SLOW).finished
	return
