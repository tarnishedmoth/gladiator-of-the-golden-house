class_name OneLiners extends Node2D

const GROUP_NAME: StringName = &"OneLiners" ## Centralized to manage timing (spam)

@export var one_liner_txt: Label

@export var is_crowd: bool = false

@export var run_random_triggers: bool = true
@export var seconds_before_starting: float = 5.0
@export var bubble_timespan_seconds: float = 2.0
@export var wait_seconds_min: float = 15.0
@export var wait_seconds_max: float = 60.0
@export var only_trigger_once: bool = false

@export var one_liners: OneLinersStrings
	
## Used to prepend one-liner (i.e. as a "response" to another bark)
## If the string ends in a space, it will print as-is.
## If not, the method handles choosing punctuation and spacing.
const AFFIRMATIVES: Array[String] = [
	"Yes",
	"You'll see",
	"Truly",
	"By the gods",
	"Well well... ",
	"Ha ha",
	"Ha",
	"Ha ha ha",
	"Ah",
	"Of course",
	"Indeed",
	"As I thought",
]
const NEGATIVES: Array[String] = [
	"No",
	"No way",
	"Impossible",
	"It can't be",
	"That's impossible",
	"Never",
	"I can't believe it",
	"I can hardly believe",
	#"Don't count me out",
	#"You can't",
	#"You mustn't",
	#"You'll die!! ",
	"Fool",
	"You fool",
	"Foolish",
	#"I can't fail",
	#"I mustn't fail",
	"I... ",
	"What-! ",
	"Gasp",
]

var bubble: Tween
var wait: Tween

func _ready():
	add_to_group(GROUP_NAME)
	#randomize()
	hide() # the bubble to begin with
	
	# wait before starting random oneliners
	if run_random_triggers:
		wait = create_tween()
		wait.tween_interval(seconds_before_starting)
		wait.tween_callback(wait_and_display_random)


############################################
# you can call this function from anywhere #
# for example, in response to getting hit! #
############################################

func say_this_oneliner(bark:String):
	if bubble:
		bubble.kill()
	bubble = create_tween()
	bubble.tween_property(self, ^"modulate", Color.WHITE, Juice.BLITZ).from(Color.TRANSPARENT) # fade in
	bubble.tween_interval(bubble_timespan_seconds) # showing
	bubble.tween_property(self, ^"modulate", Color.TRANSPARENT, Juice.SMOOTH) # fade out
	bubble.tween_callback(hide)
	
	# change the text
	one_liner_txt.text = bark
	# make bubble visible
	show()

## uses a tweener to wait for the wait interval, then displays a random oneliner.
func wait_and_display_random() -> void:
	if wait:
		wait.kill()
	
	wait = create_tween()
	wait.tween_interval(randf_range(wait_seconds_min, wait_seconds_max))
	wait.tween_callback(display_random_oneliner)
	if not only_trigger_once:
		wait.tween_callback(wait_and_display_random)

## chooses a random oneliner from [member one_liners].
func display_random_oneliner(strings: OneLinersStrings = one_liners):
	if strings == null:
		strings = one_liners
	if strings:
		say_this_oneliner(strings.pick_random())
	
## Random line with a random prefix for variety
func display_response_oneliner(positive: bool) -> void:
	if positive:
		say_this_oneliner(TextUtils.prepend(AFFIRMATIVES, one_liners.pick_random()))
	else:
		say_this_oneliner(TextUtils.prepend(NEGATIVES, one_liners.pick_random()))
