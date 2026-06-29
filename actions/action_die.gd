class_name ActionDie extends Action

## Kill the actor who runs it...

func enter(_from: ResourceState = null) -> void:
	if not _actor:
		return
	
	kill_actor(_actor)
	exit()
	
func kill_actor(actor: Actor) -> void:
	actor.die()
