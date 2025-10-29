extends TextureRect

func _ready() -> void:
	visible = not visible

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_visibility"):
		visible = not visible
