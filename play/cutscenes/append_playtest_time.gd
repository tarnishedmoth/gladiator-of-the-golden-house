extends Control

@export var add_first_time_completion_text: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not "text" in self:
		return
	
	var tool = Playtime.new()
	tool.set_seconds(PlayerData.this.combat_playtime)
	var string_time: String = tool.get_verbose_string_time()
	
	if not self.text.is_empty():
		self.text += "\n"
	self.text += "Your playtime: " + string_time
	
	if add_first_time_completion_text:
		check_add_first_time_completion_text()

func check_add_first_time_completion_text() -> void:
	if GameSettings.get_value(GameSettings.SECTION.COMPLETIONS, "game_completed", false) == true:
		self.text += "\n\n[b]You have unlocked the remaining starting classes.[/b]\n(coming in next update; your progress is saved.)\nThanks for being an early player!!"
