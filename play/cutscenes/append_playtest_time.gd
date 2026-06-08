extends Control

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
