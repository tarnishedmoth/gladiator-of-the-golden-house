class_name AIDirector extends Director

## A singular AI team coordinator that can manage multiple characters.

## We need to plan our moves and store them to be executed at the
## start of our next turn. This allows the player(s) to see our moves and strategize.
var queued_moves: Array[Callable]

func _on_turn_started():
	if VERBOSE: p("AI taking turn...")
	
	var result = await execute_queued_moves()
	
	## Tell all of our units to queue their next actions.
	## Units behave using a state machine.
	
	end_turn()

func execute_queued_moves() -> bool:
	if VERBOSE: p("Executing queued moves.")
	for move in queued_moves:
		move
		
	queued_moves.clear()
	
	return true
