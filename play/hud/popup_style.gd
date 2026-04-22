## Popup kind conventions (color, motion, font) inspired by
## https://shweep.medium.com/damage-numbers-in-rpgs-1f0e3b1bc23a
## Calmer colors and slower motion for non-damage outcomes;
## muted size for "denied satisfaction" on blocked hits.
class_name PopupStyle extends Resource

@export var color: Color = Color.WHITE
@export var label_settings: LabelSettings

@export_group("Motion")
@export var rise_distance: float = 24.0
@export var rise_duration: float = 0.6
@export var fade_duration: float = 0.2
@export var pop_scale: float = 1.3
@export var pop_duration: float = 0.12
@export var horizontal_jitter: float = 6.0
