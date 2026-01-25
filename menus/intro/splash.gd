class_name SplashMenu extends Node

signal finished

@onready var bg := %BG
@onready var studio := %Studio
@onready var title := %Title
@onready var version := %Version
@onready var subtext := %Subtext


func _ready() -> void:
	version.text = "v" + Main.get_project_version()
	await animate()
	finished.emit()

func animate() -> void:
	
	version.modulate = Color.TRANSPARENT
	Juice.fade_in(studio)
	await Juice.fade_in(title, Juice.PATIENT).finished
	await Juice.fade_in(version, Juice.SMOOTH).finished
	await Juice.flash(version, [0.22, 0.66]).finished
	
	Juice.fade_out(studio)
	Juice.fade_out(title)
	Juice.fade_out(subtext)
	await Juice.fade_out(version).finished
	return
