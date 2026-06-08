extends Sprite2D

## Autoscrolling clouds

const FADE_TIME: float = 8.0
@export var OFFSET_PER_SECOND: float = 6.5
const LOOP_TIME: float = 45.0

var scroll_tween: Tween
func _ready() -> void:
	self_modulate = Color.TRANSPARENT
	#var noise: FastNoiseLite = texture.noise
	if scroll_tween:
		if scroll_tween.is_running():
			scroll_tween.kill()
	scroll_tween = create_tween()
	scroll_tween.tween_property(self, ^"self_modulate", Color.WHITE, FADE_TIME)
	scroll_tween.parallel()
	scroll_tween.tween_property(self, ^"offset:x", offset.x + (OFFSET_PER_SECOND * LOOP_TIME), LOOP_TIME).from(0.0)
	#scroll_tween.parallel()
	#scroll_tween.tween_property(noise, ^"offset:z", (OFFSET_PER_SECOND * LOOP_TIME), LOOP_TIME).from(0.0)
	scroll_tween.chain()
	
	scroll_tween.tween_property(self, ^"self_modulate", Color.TRANSPARENT, FADE_TIME)
	scroll_tween.parallel()
	scroll_tween.tween_property(self, ^"offset:x", OFFSET_PER_SECOND * (LOOP_TIME + FADE_TIME), FADE_TIME)
	#scroll_tween.parallel()
	#scroll_tween.tween_property(noise, ^"offset:z", 0.0, LOOP_TIME)
	scroll_tween.chain()
	
	scroll_tween.tween_callback(random_flip)
	
	scroll_tween.set_loops()

func random_flip() -> void:
	flip_h = randf() > 0.5
	flip_v = randf() > 0.5
