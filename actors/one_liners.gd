class_name OneLiners extends Node2D

const GROUP_NAME: StringName = &"OneLiners" ## Centralized to manage timing (spam)

@export var one_liner_txt: Label

@export var run_random_triggers: bool = true
@export var seconds_before_starting: float = 5.0
@export var bubble_timespan_seconds: float = 2.0
@export var wait_seconds_min: float = 15.0
@export var wait_seconds_max: float = 60.0
@export var only_trigger_once: bool = false

@export var one_liners: Array[String] = [
	"Excelcior!",
	"Prepare to die!",
	"Prepare yourself.",
	"For the emperor!",
	"I do this for honor.",
	"Our names will become legend.",
	"Darkness consumes me.",
	"I do not fear death.",
	"I see storms on the horizon!",
	"I shall cut you down.",
	"For glory!",
	"Imperium vitae!",
	"Deus Vult!", # god wills it in latin
	"Signa inferre!", # signals forward latin
	"Mars Ultor!", # god of war the avenger
	"Desperta Ferro!", # Awaken Iron!
	"Si vis pacem, para bellum", # If you want peace, prepare for war
	"Omnia vincit amor.", # Love conquers all - often used ironically
	"Ad astra per aspera!", # To the stars through difficulties
	"Morituri te salutant.", # those who are about to die salute you
	"Silence!",
	"Respect!",
	"Glory!",
	"Honor!",
	"Victory!",
	"Today is a good day to die!",
	"Are you not entertained?",
	"Strength and honor!",
	"What we do in life echoes in eternity.",
	"Tennoheika Banzai!", # Japanese for 10,000 years! (long live the emperor)
	"Oorah!",
	"I shall defeat you!",
	]
	
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
	"Don't count me out",
	"You can't",
	"You mustn't",
	"You'll die!! ",
	"Fool",
	"You fool",
	"Foolish",
	"I can't fail",
	"I mustn't fail",
	"I... ",
	"What-! ",
	"Gasp",
]

var one_liner_delay_remaining:float = 0.0
var bubble_time_remaining:float = 0.0


############################################
# you can call this function from anywhere #
# for example, in response to getting hit! #
############################################
func say_this_oneliner(bark:String):
	#print("one liner: "+bark)
	# show the bubble for a while
	bubble_time_remaining = bubble_timespan_seconds
	# plus a random delay afterwards before barks continue
	one_liner_delay_remaining = randf_range(wait_seconds_min, wait_seconds_max)
	# change the text
	one_liner_txt.text = bark
	# make bubble visible
	show()

func _ready():
	add_to_group(GROUP_NAME)
	#randomize()
	hide() # the bubble to begin with
	# wait before starting random oneliners
	one_liner_delay_remaining = seconds_before_starting
	# we could add extra so other NPCs don't start at the same time:
	one_liner_delay_remaining += randf_range(wait_seconds_min, wait_seconds_max)

func display_random_oneliner():
	# choose one randomly
	# TODO avoid repeats? go in sequence+loop from a random start index?
	var string = one_liners[randi() % one_liners.size()]
	say_this_oneliner(string)
	
## Random line with a random prefix for variety
func display_response_oneliner(positive: bool) -> void:
	if positive:
		say_this_oneliner(TextUtils.prepend(AFFIRMATIVES, one_liners.pick_random()))
	else:
		say_this_oneliner(TextUtils.prepend(NEGATIVES, one_liners.pick_random()))

func _process(delta):
	if not run_random_triggers:
		return
	bubble_time_remaining -= delta
	if (bubble_time_remaining > 0.0):
		return # keep showing it
	else:
		hide() # the bubble
	
	one_liner_delay_remaining -= delta
	if one_liner_delay_remaining <= 0.0:
		display_random_oneliner()
		if only_trigger_once: one_liner_delay_remaining = INF
		
