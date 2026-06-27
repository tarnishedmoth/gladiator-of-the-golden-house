class_name Cutscene extends Node2D

enum PlayMusic {
	NONE,
	TRACK_SHERMAN,
	TRACK_VAILLANCOURT
}

@export var time_left_to_skip: float = 3.0

@export var play_music: PlayMusic = PlayMusic.NONE
@export var only_play_track_if_not_playing: bool = true

@export var kill_music_at_end: bool = false
@export var use_scene_blocking_transition_on_exit: bool = true
@export var use_scene_blocker_style: Main.SceneBlockers = Main.SceneBlockers.DARK

var is_exiting: bool = false

func _ready() -> void:
	var t: Tween = create_tween()
	t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_property(self, ^"time_left_to_skip", -0.01, time_left_to_skip)
	
	match play_music:
		PlayMusic.TRACK_SHERMAN:
			if only_play_track_if_not_playing:
				if not Main.get_instance().music_sherman.playing:
					Main.play_sherman(true)
			else:
				Main.play_sherman(true)
		PlayMusic.TRACK_VAILLANCOURT:
			if only_play_track_if_not_playing:
				if not Main.get_instance().music_vaillancourt.playing:
					Main.play_vaillancourt(true)
			else:
				Main.play_vaillancourt(true)

func on_finished() -> void:
	if is_exiting:
		return
	is_exiting = true
	if kill_music_at_end:
		Main.play_music_menu_loop(false)
		match play_music:
			PlayMusic.TRACK_SHERMAN:
				Main.play_sherman(false)
			PlayMusic.TRACK_VAILLANCOURT:
				Main.play_vaillancourt(false)
		
	await Juice.fade_out(self, Juice.SMOOTH, Color.BLACK).finished
	Main.register_level_progressed()
	Main.load_latest_level()

func skip() -> void:
	if not time_left_to_skip > 0.0:
		use_scene_blocking_transition_on_exit = true
		Main.sfx_blip()
		on_finished()

func go_to_main_menu() -> void:
	if not time_left_to_skip > 0.0:
		is_exiting = true
		Main.go_to_main_menu()
