extends Node

@export var hide_on_enter: bool = false ## If true, hides instead of deletes.

func _enter_tree() -> void:
	if hide_on_enter:
		if "hide" in self:
			self.hide.call()
	else:
		queue_free()
