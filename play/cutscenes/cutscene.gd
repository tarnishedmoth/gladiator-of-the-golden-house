class_name Cutscene extends Node2D

func on_finished() -> void:
	await Juice.fade_out(self, Juice.SMOOTH, Color.BLACK).finished
	Main.register_level_progressed()
	Main.load_latest_level()
