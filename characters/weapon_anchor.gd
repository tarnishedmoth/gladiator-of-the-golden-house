class_name WeaponAnchorer extends Marker2D

## combined functionality for both anchor markers and nodes that much align to the marker.
## If configured as an Anchor, registers to the Actor node.
## If configured as a Weapon, reparents itself to the Anchor node on ready.

enum Type {
	ANCHOR = 0,
	WEAPON = 1
}

@export var enabled: bool = true ## Set to false to retain this in the scene, but this node will not do its function.
@export var which: Type

var anchor: Node:
	set(v):
		anchor = v
		_on_anchor_configured()
		
func set_anchor(node: Node) -> void: anchor = node

func _ready() -> void:
	if not enabled:
		return
	var actor: Actor
	var node: Node = self
	for i in 4:
		if node == null:
			break
		node = node.get_parent()
		if node != null:
			if node is Actor:
				actor = node
				break
	if actor:
		if which == Type.ANCHOR:
			actor.register_anchor(self)
		else:
			if actor.anchor_hand:
				anchor = actor.anchor_hand
			else:
				push_warning("Actor doesn't have anchor")
				actor.subscribe_weapon(self)
				hide()

func _on_anchor_configured() -> void:
	var _position: Vector2 = self.position
	get_parent().remove_child(self)
	anchor.add_child(self)
	self.position = _position
	show()
