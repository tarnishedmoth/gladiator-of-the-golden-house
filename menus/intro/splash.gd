class_name SplashMenu extends Node

signal finished

@onready var bg: ColorRect = %BG
@onready var studio: TextureRect = %Studio
@onready var title: Label = %Title
@onready var version: Label = %Version
@onready var subtext: Label = %Subtext


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
