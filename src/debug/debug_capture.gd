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
##     DebugCapture.register_provider("Patience", func() -> Dictionary:
##         return {"patience": _patience, "max": _max_patience})
##
## Later tickets call DebugCapture.capture("run ended"), capture("victory")
## and so on for automatic snapshots.

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
func capture(reason: String) -> String:
	if not is_active():
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


func _save_rolling_screenshot() -> void:
	var folder: String = root_folder.path_join("rolling")
	DirAccess.make_dir_recursive_absolute(folder)
	var file_name: String = CaptureFiles.timestamp_name(Time.get_datetime_dict_from_system()) + ".png"
	await _save_screenshot_after_draw(CaptureFiles.unused_path(folder.path_join(file_name)), false)
	CaptureFiles.keep_newest(folder, "png", ROLLING_KEEP)


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
