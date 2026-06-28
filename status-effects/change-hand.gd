class_name StatusHand extends Status

## affect the player's hand

const META_MARKER: StringName = &"TEMP"

enum Inserts {
	HAND = 0, ## Insert the card directly into their hand and refresh the actions list
	DRAW_DECK = 1, ## Insert the card into their draw pile
	DISCARD_DECK = 2, ## Insert the card into their discard pile
	STASH = 3, ## Insert the card directly into their stash and refresh the actions list
	ALWAYS_AVAILABLE_ACTIONS = 4, ## Careful or this could break things quick
}

enum Locations {
	TOP, ## Insert at the top of the deck
	BOTTOM, ## Insert at the bottom of the deck
	RANDOM ## Insert in a random place in the deck
}

@export var hook: Hook
@export var cards: Array[Action]
@export var where: Inserts
@export var location: Locations ## Only relevant for Draw Deck used in [member where]

func do_thing() -> void: # the thing jack
	if cards.is_empty():
		push_warning("No cards configured to be pushed")
		return
	
	if not _actor:
		push_error("No actor configured")
		return
	
	if not _actor.director is Player:
		push_warning("Only usable on Player director: %s" % _actor.director)
		## AI directors don't have "cards", the actors hold all usable actions at once.
		return
	
	var player = _actor.director as Player
	
	var dup_cards: Array[Action]
	for card in cards:
		var dup: Action = card.duplicate()
		dup.set_meta(META_MARKER, true)
		dup_cards.push_back(dup)
	
	match where:
		Inserts.HAND:
			for card in dup_cards:
				player.actions_in_hand.push_front(card)
			player.refresh_hud_actions_and_stash()
		
		Inserts.DRAW_DECK:
			for card in dup_cards:
				match location:
					Locations.TOP:
						player.draw_deck.push_front(card)
					Locations.BOTTOM:
						player.draw_deck.push_back(card)
					Locations.RANDOM:
						player.draw_deck.insert(
							randi_range(0, player.draw_deck.size())
						)
		
		Inserts.DISCARD_DECK:
			for card in dup_cards:
				player.discard_deck.push_back(card)
		
		Inserts.STASH:
			for card in dup_cards:
				player.add_to_stash(card)
			player.refresh_hud_actions_and_stash()
		
		Inserts.ALWAYS_AVAILABLE_ACTIONS:
			for card in dup_cards:
				player.always_available_deck.push_back(card)
			#player.refresh_hud_actions_and_stash()
	


func on_turn_start() -> void: ## Call super() if you override
	if hook != Hook.ON_TURN_START:
		return
	
	do_thing()
	on_after_hook()
	super()

func on_turn_end() -> void: ## Call super() if you override
	if hook != Hook.ON_TURN_END:
		return
	
	do_thing()
	on_after_hook()
	super()

func on_deal_damage(damage: int) -> int: ## Override me
	if hook != Hook.ON_DEAL_DAMAGE:
		return damage
	
	do_thing()
	on_after_hook()
	return damage

func on_deal_direct_damage(damage: int) -> int: ## Override me
	if hook != Hook.ON_DEAL_DIRECT_DAMAGE:
		return damage
	
	do_thing()
	on_after_hook()
	return damage

func on_take_damage(damage: int) -> int: ## Override me
	if hook != Hook.ON_TAKE_DAMAGE:
		return damage
	
	do_thing()
	on_after_hook()
	return damage

func on_take_direct_damage(damage: int) -> int: ## Override me
	if hook != Hook.ON_TAKE_DIRECT_DAMAGE:
		return damage
	
	do_thing()
	on_after_hook()
	return damage

## Called when actor just began applying a new status effect.
func on_applying_status(new_status: Status) -> Status: ## Override me
	if hook != Hook.ON_APPLYING_STATUS:
		return new_status
	
	do_thing()
	on_after_hook()
	return new_status

@warning_ignore("unused_parameter")
## Happens after damage has been dealt by the actor with this status. The value can not be manipulated. Override me.
func on_damage_dealt(damage:int) -> void:
	if hook != Hook.ON_DAMAGE_DEALT:
		return
	
	do_thing()
	on_after_hook()

@warning_ignore("unused_parameter")
## Happens after damage has been dealt by the actor with this status. The value can not be manipulated. Override me.
func on_direct_damage_dealt(damage:int) -> void:
	if hook != Hook.ON_DIRECT_DAMAGE_DEALT:
		return
	
	do_thing()
	on_after_hook()
	
@warning_ignore("unused_parameter")
## Happens after some other status has been applied to the actor with this status.
func on_status_applied(new_status: Status) -> void:
	if hook != Hook.ON_STATUS_APPLIED:
		return
	
	do_thing()
	on_after_hook()
