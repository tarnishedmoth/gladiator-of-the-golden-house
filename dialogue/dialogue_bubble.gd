class_name DialogueBubble extends Node2D

@export var timer: Timer
@export var duration: float
@export var dialogue: RichTextLabel

func _ready() -> void:
	self.modulate = Color.TRANSPARENT

func speak(speech:String) -> void:
	print("Start talking")
	_populate_speech_bubble(speech)
	_show_dialogue(true)
	timer.start(duration)
	await timer.timeout
	_show_dialogue(false)
	
func _populate_speech_bubble(speech:String) -> void: 
	dialogue.text = ""
	dialogue.text = speech

func _show_dialogue(vis:bool) -> void:
	if vis:
		Juice.fade_in(self)
	else:
		Juice.fade_out(self)

func _on_timer_stop() -> void:
	_show_dialogue(false)

#func on_hover_exit_dialogue
	#unpause timer
