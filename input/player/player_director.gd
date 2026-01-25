class_name Player extends Director

const HOLD_TIME_TO_END_TURN_EARLY: float = 2.5

func _on_turn_started():
	if VERBOSE: p("Player turn started")
	pass
	
var _end_turn_with_available_moves: Tween
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"open_pause_menu"):
			get_tree().quit() ## FIXME
			pass
	
	if is_active:
		if event.is_action_pressed(&"end_turn"):
			#if still have available moves:
				#_end_turn_with_available_moves = create_tween()
				#_end_turn_with_available_moves.tween_interval(HOLD_TIME_TO_END_TURN_EARLY)
				#_end_turn_with_available_moves.tween_callback(end_turn)
			#else:
			end_turn()
		elif event.is_action_released(&"end_turn"):
			if _end_turn_with_available_moves:
				if _end_turn_with_available_moves.is_valid():
					_end_turn_with_available_moves.kill()
		
	else:
		pass
