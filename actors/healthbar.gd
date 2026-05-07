class_name Healthbar extends Sprite2D

@onready var bar: Sprite2D = $bar
@onready var txt: Label = $txt

var tween: Tween

func show_() -> void:
	if tween:
		tween.kill()
	bar.modulate = Color.WHITE
	modulate = Color.WHITE
	show()

func update_healthbar(health: float, max_health: float) -> void:
	if bar:
		bar.scale.x = health/max_health
	if txt:
		txt.text = str(int(health))
	
	modulate = Color.WHITE
	show()
	
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(bar, ^"modulate", Color.DIM_GRAY, Juice.SNAP).from(Color.WHITE)
	tween.tween_property(bar, ^"modulate", Color.DIM_GRAY, Juice.SNAP).from(Color.WHITE)
	tween.tween_property(bar, ^"modulate", Color.DIM_GRAY, Juice.SNAP).from(Color.WHITE)
	
	tween.tween_property(bar, ^"modulate", Color.WHITE, Juice.SNAPPY)
	tween.tween_interval(1.5)
	tween.tween_callback(fade_out)

func fade_out() -> void:
	if visible:
		if tween:
			tween.kill()
		tween = create_tween()
		tween.tween_property(self, ^"modulate", Color.TRANSPARENT, 1.8)
		tween.tween_callback(hide)
