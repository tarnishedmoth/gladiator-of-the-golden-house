extends AudioStreamPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var t = create_tween()
	t.set_loops()
	t.set_trans(Tween.TRANS_SINE)
	t.tween_property(self, ^"volume_db", volume_db - 8.0, 10.0)
	t.tween_property(self, ^"volume_db", volume_db - 3.0, 20.0)
	t.tween_property(self, ^"volume_db", volume_db, 3.0)
