@tool
extends Node2D

@export var particles_enabled: bool = false:
	set(v):
		particles_enabled = v
		update_particles()

@export var nonemissive_modulate: Color = Color.WHITE:
	set(v):
		nonemissive_modulate = v
		update_nonemissive_modulate()
		
@export var start_red: bool = false:
	set(v):
		if start_red == false && v == true:
			reveal_red()
		elif start_red == true && v == false:
			backdrop_red.modulate = Color.TRANSPARENT
		start_red = v

@export var transition_to_color: Color
@export var transition_time: float = 6.0
@export_tool_button("Transition to Red") var transition = transition_to_red_and_start_particles

@onready var rune_particles: GPUParticles2D = $RuneParticles
@onready var nonemissive: Node2D = $Nonemissive
@onready var backdrop_clean: Sprite2D = $Nonemissive/BackdropClean
@onready var backdrop_red: Sprite2D = $Nonemissive/BackdropRed

@onready var crowd: Node2D = $Nonemissive/Crowd


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if start_red:
		backdrop_red.modulate = Color.WHITE
	else:
		backdrop_red.modulate = Color.TRANSPARENT
	
	update_particles()
	update_nonemissive_modulate()
	
func update_particles():
	if rune_particles:
		rune_particles.emitting = particles_enabled

func update_nonemissive_modulate():
	if nonemissive:
		var tween: Tween = create_tween()
		tween.tween_property(nonemissive, ^"modulate", nonemissive_modulate, transition_time)

func reveal_red() -> Tween:
	return Juice.fade_in(backdrop_red, 6.0, Color.TRANSPARENT)

func transition_to_red_and_start_particles() -> void:
	reveal_red()
	particles_enabled = true
	if transition_to_color:
		nonemissive_modulate = transition_to_color
