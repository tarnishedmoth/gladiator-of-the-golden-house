class_name SplashMenu extends Node

signal finished

@onready var ui: Control = $UI
@onready var bg := %BG
@onready var studio: Sprite2D = %Studio
@onready var title := %Title
@onready var version := %Version
@onready var side_logos: Control = $UI/SideLogos
@onready var margin_container: MarginContainer = $UI/MarginContainer

func _ready() -> void:
	version.text = "v" + Main.get_project_version()
	await animate()
	finished.emit()

func animate() -> void:
	Juice.fade_in(ui, Juice.SLOW)
	var tween: Tween = create_tween()
	tween.tween_property(margin_container, "position", margin_container.position + Vector2.UP * 60.0, 8.0).set_ease(Tween.EASE_IN)
	
	version.modulate = Color.TRANSPARENT
	Juice.fade_in(studio)
	await Juice.fade_in(title, Juice.PATIENT).finished
	await Juice.fade_in(version, Juice.SMOOTH).finished
	await Juice.flash(version, [0.22, 0.66]).finished
	await get_tree().create_timer(1.0).timeout
	Juice.fade_out(studio)
	Juice.fade_out(title)
	Juice.fade_out(version)
	Juice.fade_out(side_logos)
	await Juice.fade_out(ui, Juice.SLOW).finished
	return
