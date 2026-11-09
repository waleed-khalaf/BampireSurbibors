extends Node
## Autoload "DebugCapture" (Project Settings > Globals): the debug capture
## service. Dev builds only; in an exported release build it does nothing.
##
## - Every 5 s it saves a screenshot to debug_captures/rolling/ and keeps the
##   newest 60, so the last ~5 minutes of play can be looked at afterwards.
## - F12, or a call to [method capture], saves a bug snapshot: a folder named
##   by date, time and reason holding screenshot.png and state.txt.
##
## The service knows nothing about the game. Systems describe their own state
## through state providers, so a new system shows up in state.txt without this
## file changing:
##
##     DebugCapture.register_provider("Music", func() -> Dictionary:
##         return {"track": _track_name, "beat": _beat})
##
## RunView calls DebugCapture.capture("run ended") when a run ends, for an
## automatic snapshot. Later tickets add capture("victory") and so on.

const ROLLING_INTERVAL: float = 5.0
const ROLLING_KEEP: int = 60
const LOG_ENTRIES: int = 20
const TOAST_SECONDS: float = 2.0

## Where captures go. Empty means the default: debug_captures/ in the project
## folder (gitignored), or in the user data folder for an exported debug build,
## whose res:// is read-only. Tests point it somewhere else before the node
## enters the tree.
var root_folder: String = ""

## Rolling screenshots on or off. They're always off when there is no window
## (a headless run such as the test suite), because nothing is drawn.
var rolling_enabled: bool = true

var _active: bool = false
var _log: CaptureLog
var _providers: Dictionary[String, Callable] = {}
## True from a rolling tick until its screenshot is on disk. Godot only draws
## while the window is visible, so a save started while the game is minimized
## waits until it is restored. Without this flag every 5 s tick during that
## spell would park one more waiting save, and on restore they would all wake
## in the same frame and write the same screenshot several times.
var _rolling_save_pending: bool = false
var _timer: Timer
var _toast: Label
var _toast_tween: Tween


func _ready() -> void:
	# Keep working while the game is paused: a pause menu bug needs captures too.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_active = OS.is_debug_build()
	if not _active:
		set_process_input(false)
		return
	if root_folder.is_empty():
		root_folder = _default_root_folder()
	_prepare_root_folder()
	_log = CaptureLog.new(LOG_ENTRIES)
	OS.add_logger(_log)
	if rolling_enabled and _has_window():
		_start_rolling()
	_build_toast()


func _exit_tree() -> void:
	if _log != null:
		OS.remove_logger(_log)
		_log = null


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_capture"):
		capture("f12")
		get_viewport().set_input_as_handled()


## Whether captures are being made (a debug build, and the service is ready).
func is_active() -> bool:
	return _active and _log != null


## Adds a section to every state.txt. [param provider] takes no arguments and
## returns a Dictionary of names to values; it is called at capture time, so
## the values are always current. Registering a [param section] again replaces
## the old provider. Sections appear in the order they were first registered.
func register_provider(section: String, provider: Callable) -> void:
	_providers[section] = provider


## Removes a section, for example when its system leaves the scene tree.
## A provider whose object was freed is dropped on its own at the next capture.
func unregister_provider(section: String) -> void:
	_providers.erase(section)


## Saves a bug snapshot: a new folder named like "2026-11-06_14-03-22_f12"
## holding state.txt (written now) and screenshot.png (written once the
## current frame has been drawn). [param reason] says why, e.g. "f12",
## "run ended", "victory" or "error". Returns the folder's path, or "" when
## captures are off.
##
## Never call this straight from a Logger callback or from another thread: it
## prints (which would call the Logger again) and touches the scene tree (main
## thread only). Defer it, e.g. DebugCapture.capture.call_deferred("error"),
## and Godot runs it on the main thread at the end of the frame instead.
func capture(reason: String) -> String:
	if not is_active():
		return ""
	# Again, not only at start-up: the folder may have been deleted since.
	if not _prepare_root_folder():
		return ""
	var folder_name: String = "%s_%s" % [CaptureFiles.timestamp_name(Time.get_datetime_dict_from_system()), CaptureFiles.slug(reason)]
	var folder: String = CaptureFiles.unused_path(root_folder.path_join(folder_name))
	var error: Error = DirAccess.make_dir_recursive_absolute(folder)
	if error != OK:
		push_error("Debug capture: could not create %s (%s)." % [folder, error_string(error)])
		return ""

	var screenshot_note: String = "screenshot.png" if _has_window() else "none (no window: headless run)"
	_write_text(folder.path_join("state.txt"), _state_text(reason, screenshot_note))
	print("Debug capture saved: %s" % folder)
	if _has_window():
		_save_screenshot_after_draw(folder.path_join("screenshot.png"), true)
	return folder


func _start_rolling() -> void:
	_timer = Timer.new()
	_timer.wait_time = ROLLING_INTERVAL
	_timer.ignore_time_scale = true
	_timer.timeout.connect(_save_rolling_screenshot)
	add_child(_timer)
	_timer.start()


## Saves one rolling screenshot, named by the clock, and prunes the folder.
## Called by the 5 s timer; a tick that arrives while an earlier save is still
## waiting for a frame is skipped.
func _save_rolling_screenshot() -> void:
	# One waiting save is enough (see _rolling_save_pending): a second tick
	# while the window is minimized would only add a copy of the same screenshot.
	if _rolling_save_pending:
		return
	if not _prepare_root_folder():
		return
	_rolling_save_pending = true
	var folder: String = root_folder.path_join("rolling")
	DirAccess.make_dir_recursive_absolute(folder)
	# Read the clock only once a frame has actually been drawn. A save that sat
	# through a minimized spell is then named by when play resumed, not by when
	# the tick happened minutes earlier. The screenshot itself is the next
	# frame, a fraction of a second after the name.
	await RenderingServer.frame_post_draw
	var file_name: String = CaptureFiles.timestamp_name(Time.get_datetime_dict_from_system()) + ".png"
	await _save_screenshot_after_draw(CaptureFiles.unused_path(folder.path_join(file_name)), false)
	CaptureFiles.keep_newest(folder, "png", ROLLING_KEEP)
	_rolling_save_pending = false


## Waits for the frame being built to finish drawing, then saves it. Called
## without await, the caller carries on at once and the file appears a frame
## later.
func _save_screenshot_after_draw(path: String, show_toast: bool) -> void:
	await RenderingServer.frame_post_draw
	var image: Image = get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		push_warning("Debug capture: the screen could not be read, so %s was not saved." % path)
		return
	var error: Error = image.save_png(path)
	if error != OK:
		push_error("Debug capture: could not save %s (%s)." % [path, error_string(error)])
		return
	# Shown only after the screenshot is taken, so it never covers the bug.
	if show_toast:
		_show_toast("Debug capture saved")


func _state_text(reason: String, screenshot_note: String) -> String:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("== Debug capture ==")
	lines.append("reason: %s" % reason)
	lines.append("captured: %s" % Time.get_datetime_string_from_system(false, true))
	lines.append("fps: %d" % Engine.get_frames_per_second())
	lines.append("screenshot: %s" % screenshot_note)
	lines.append("godot: %s" % Engine.get_version_info().string)

	if _providers.is_empty():
		lines.append("")
		lines.append("(no state providers registered)")
	for section: String in _providers.keys():
		lines.append("")
		lines.append("== %s ==" % section)
		lines.append_array(_provider_lines(section))

	lines.append("")
	lines.append("== Last %d log lines (oldest first) ==" % LOG_ENTRIES)
	lines.append_array(_or_none(_log.recent_lines()))
	lines.append("")
	lines.append("== Last %d errors and warnings (oldest first) ==" % LOG_ENTRIES)
	lines.append_array(_or_none(_log.recent_errors()))
	return "\n".join(lines) + "\n"


func _provider_lines(section: String) -> PackedStringArray:
	var provider: Callable = _providers[section]
	if not provider.is_valid():
		# Its object was freed without unregistering. Drop it for good.
		_providers.erase(section)
		return PackedStringArray(["(provider is gone: its object was freed)"])
	var state: Variant = provider.call()
	if not state is Dictionary:
		return PackedStringArray(["(provider returned %s, expected a Dictionary)" % type_string(typeof(state))])
	var lines: PackedStringArray = PackedStringArray()
	for key: Variant in state:
		lines.append("%s: %s" % [key, _format_value(state[key])])
	if lines.is_empty():
		lines.append("(empty)")
	return lines


## Short, readable values: positions to one decimal, not nine.
static func _format_value(value: Variant) -> String:
	match typeof(value):
		TYPE_FLOAT:
			return "%.2f" % value
		TYPE_VECTOR2:
			return "(%.1f, %.1f)" % [value.x, value.y]
		_:
			return str(value)


static func _or_none(entries: PackedStringArray) -> PackedStringArray:
	return entries if not entries.is_empty() else PackedStringArray(["(none)"])


static func _write_text(path: String, text: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Debug capture: could not write %s (%s)." % [path, error_string(FileAccess.get_open_error())])
		return
	file.store_string(text)


## Creates the capture folder if needed and puts an empty .gdignore in it.
## The default folder sits inside the project, and the Godot editor imports
## every PNG it finds there as a texture (adding .png.import files that the
## rolling clean-up never deletes). .gitignore means nothing to that scan;
## a .gdignore file makes the editor skip the folder entirely. Returns false
## (after reporting the error) when the folder could not be created.
func _prepare_root_folder() -> bool:
	var error: Error = DirAccess.make_dir_recursive_absolute(root_folder)
	if error != OK:
		push_error("Debug capture: could not create %s (%s)." % [root_folder, error_string(error)])
		return false
	var marker: String = root_folder.path_join(".gdignore")
	if not FileAccess.file_exists(marker):
		_write_text(marker, "")
	return true


static func _default_root_folder() -> String:
	if OS.has_feature("template"):
		return OS.get_user_data_dir().path_join("debug_captures")
	return ProjectSettings.globalize_path("res://debug_captures")


static func _has_window() -> bool:
	return DisplayServer.get_name() != "headless"


func _build_toast() -> void:
	# Its own layer, drawn above the HUD and every menu.
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_toast = Label.new()
	_toast.position = Vector2(8, 8)
	_toast.add_theme_color_override("font_outline_color", Color.BLACK)
	_toast.add_theme_constant_override("outline_size", 4)
	_toast.visible = false
	layer.add_child(_toast)


func _show_toast(text: String) -> void:
	_toast.text = text
	_toast.visible = true
	_toast.modulate.a = 1.0
	if _toast_tween != null:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(TOAST_SECONDS)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.3)
	_toast_tween.tween_callback(_toast.hide)
