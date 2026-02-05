class_name Director extends Node2D

## Has control of game actor(s). This could be the player, or enemy AI.
## If this were multiplayer, this is like different players. All characters on
## the game board on the same team should be controlled by one director.
##
## We will likely only ever have two Directors in a game at once, the player and
## the AI enemy director. But this architecture does open the possibility for
## shared screen multiplayer or maybe multiple AI directors, allies or enemies.

signal turn_taken(Director)

const VERBOSE:bool = true

var actors: Array[Actor] ## Order of items in array is important.

var is_active: bool = false

func p(args):
	print_rich("[bgcolor=black][color=white]", "Director %s : " % name, args)

##
## CRITICAL
##
## Do not override in extending classes.
##
## Fire this when giving control/agency to this director to take their turn.
## Called by [Level].
func take_turn() -> void:
	## Do turn stuff
	is_active = true
	if VERBOSE: p("It's my turn!..")
	_on_turn_started()
	
## Not intended to interrupt, but to indicate we are finished.
## Call this in your extending class to end the turn.
func end_turn() -> void:
	## Indicate we're done
	is_active = false
	if VERBOSE: p("Ending turn...")
	turn_taken.emit(self)

##
## CRITICAL
##
## Override me in extending classes. And do turn stuff.
func _on_turn_started():
	if VERBOSE: print_debug("Method not overriden--check extending class script.")
	pass


func clear_and_repopulate_actors_from_children() -> void:
	actors.clear()
	for child in get_children():
		if child is Actor:
			actors.push_back(child)
