class_name StatusTemplate extends Status

## Just a template script for extending, with an optional hook (to configure in the inspector).
## If implementing a choice of hook, call [method on_after_hook] to use built-in
## effect points behavior after your logic.

#@export var hook: Hook

func do_thing() -> void:
	pass

#func on_turn_start() -> void: ## Call super() if you override
	#if hook != Hook.ON_TURN_START:
		#return
	#
	#do_thing()
	#on_after_hook()
	#super()
#
#func on_turn_end() -> void: ## Call super() if you override
	#if hook != Hook.ON_TURN_END:
		#return
	#
	#do_thing()
	#on_after_hook()
	#super()
#
#func on_deal_damage(damage: int) -> int: ## Override me
	#if hook != Hook.ON_DEAL_DAMAGE:
		#return damage
	#
	#do_thing()
	#on_after_hook()
	#return damage
#
#func on_deal_direct_damage(damage: int) -> int: ## Override me
	#if hook != Hook.ON_DEAL_DIRECT_DAMAGE:
		#return damage
	#
	#do_thing()
	#on_after_hook()
	#return damage
#
#func on_take_damage(damage: int) -> int: ## Override me
	#if hook != Hook.ON_TAKE_DAMAGE:
		#return damage
	#
	#do_thing()
	#on_after_hook()
	#return damage
#
#func on_take_direct_damage(damage: int) -> int: ## Override me
	#if hook != Hook.ON_TAKE_DIRECT_DAMAGE:
		#return damage
	#
	#do_thing()
	#on_after_hook()
	#return damage
#
### Called when actor just began applying a new status effect.
#func on_applying_status(new_status: Status) -> Status: ## Override me
	#if hook != Hook.ON_APPLYING_STATUS:
		#return new_status
	#
	#do_thing()
	#on_after_hook()
	#return new_status
#
#@warning_ignore("unused_parameter")
### Happens after damage has been dealt by the actor with this status. The value can not be manipulated. Override me.
#func on_damage_dealt(damage:int) -> void:
	#if hook != Hook.ON_DAMAGE_DEALT:
		#return
	#
	#do_thing()
	#on_after_hook()
#
#@warning_ignore("unused_parameter")
### Happens after damage has been dealt by the actor with this status. The value can not be manipulated. Override me.
#func on_direct_damage_dealt(damage:int) -> void:
	#if hook != Hook.ON_DIRECT_DAMAGE_DEALT:
		#return
	#
	#do_thing()
	#on_after_hook()
	#
#@warning_ignore("unused_parameter")
### Happens after some other status has been applied to the actor with this status.
#func on_status_applied(new_status: Status) -> void:
	#if hook != Hook.ON_STATUS_APPLIED:
		#return
	#
	#do_thing()
	#on_after_hook()
