class_name Cutscene extends Node2D

@export var kill_music_at_end: bool = false

func on_finished() -> void:
	if kill_music_at_end:
		Main.play_music_menu_loop(false)
		
	await Juice.fade_out(self, Juice.SMOOTH, Color.BLACK).finished
	Main.register_level_progressed()
	Main.load_latest_level()
