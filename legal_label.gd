class_name LegalLabel extends RichTextLabel

## Automatically populates with the required license info.
## 
## Godot asks that you show this license information with any game you make.
## Show this info in a menu available in your game for players to see.
## Something to note is that line breaks are preformatted in the Engine methods,
## so avoid using Word Wrap, and instead size your font and control width.
## 
## [br][br]See https://docs.godotengine.org/en/4.5/about/complying_with_licenses.html
## [br][method Engine.get_license_text]
## [br][method Engine.get_license_info]
## [br][method Engine.get_copyright_info]

func _ready() -> void:
	generate_legal_text()
	
func generate_legal_text() -> void:
	text = TextUtils.bold("Godot Engine") + "\n"
	text += Engine.get_license_text()
	var license_info:Dictionary = Engine.get_license_info()
	for i in license_info:
		text += "\n"
		text += TextUtils.bold(i) + "\n"
		text += license_info[i]
