extends Node
## Autoload (always loaded, see Project Settings > Globals) so F11 toggles
## fullscreen from any screen, including menus and while the game is paused.


func _ready() -> void:
	# Keep listening even when the scene tree is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("fullscreen"):
		_toggle()
		get_viewport().set_input_as_handled()


func _toggle() -> void:
	var mode: DisplayServer.WindowMode = DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
