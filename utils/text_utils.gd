class_name TextUtils

## Puts BBCode around your provided text content.

static func ital(v) -> String: return "[i]" + str(v) + "[/i]"
static func bold(v) -> String: return "[b]" + str(v) + "[/b]"
static func underl(v) -> String: return "[u]" + str(v) + "[/u]"
static func brac(v) -> String: return "[" + str(v) + "]"
static func center(v) -> String: return "[center]" + str(v) + "[/center]"

## Returns an identical string with a lowercase first letter.
static func lowercase_front(string: String) -> String:
	return string.left(1).to_lower() + string.right(-1)

static func prepend(prefixes: Array[String], string: String) -> String:
	var prefix: String = prefixes.pick_random()
	if prefix.ends_with(" "):
		return prefix + string
	else:
		match randi_range(0,4):
			0: ## Period
				return prefix + ". " + string
			1: ## Comma
				return prefix + ", " + TextUtils.lowercase_front(string)
			2: ## em dash
				return prefix + "—" + TextUtils.lowercase_front(string)
			3: ## Exclamation
				return prefix + "! " + string
			4: ## Contemplation
				return prefix + "... " + TextUtils.lowercase_front(string)
			_: ## NOTE Required to parse method... never called
				return prefix + string
