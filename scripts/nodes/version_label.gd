extends Label


func _ready():
	text = (
		"v-%s\nbuild-%s"
		% [
			ProjectSettings.get_setting("application/config/version"),
			ProjectSettings.get_setting("application/config/build")
		]
	)
