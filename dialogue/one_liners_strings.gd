class_name OneLinersStrings extends Resource

## Package of usable strings. Allows us to reuse this resource among many nodes.
## Theoretically this also allows us to modify a shared resource to update the
## speech used in real time, making it highly reactive (potentially).

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

func pick_random() -> String:
	return one_liners.pick_random()
