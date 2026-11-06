class_name CaptureLog
extends Logger
## Remembers the most recent log output so a debug capture can include it.
##
## Godot hands every print(), printerr(), push_warning(), push_error() and
## script error to each registered Logger (see OS.add_logger). This one keeps
## two short histories: plain log lines, and errors and warnings. They are kept
## apart so a burst of prints can't push the one error you care about out of
## the dump.
##
## Godot may call a Logger from any thread, so the histories sit behind a
## mutex. A Logger must never print: that would call it again, forever.

var _max_entries: int
var _lines: Array[String] = []
var _errors: Array[String] = []
var _mutex: Mutex = Mutex.new()


func _init(max_entries: int = 20) -> void:
	_max_entries = max_entries


## The newest plain log lines, oldest first.
func recent_lines() -> PackedStringArray:
	_mutex.lock()
	var copy := PackedStringArray(_lines)
	_mutex.unlock()
	return copy


## The newest errors and warnings, oldest first.
func recent_errors() -> PackedStringArray:
	_mutex.lock()
	var copy := PackedStringArray(_errors)
	_mutex.unlock()
	return copy


func _log_message(message: String, error: bool) -> void:
	# One print can hold several lines; each one is an entry.
	for line: String in message.strip_edges(false, true).split("\n"):
		if error:
			_append(_errors, "%s printerr: %s" % [_clock(), line])
		else:
			_append(_lines, "%s %s" % [_clock(), line])


func _log_error(function: String, file: String, line: int, code: String, rationale: String,
		_editor_notify: bool, error_type: int, script_backtraces: Array[ScriptBacktrace]) -> void:
	# Engine errors (the ERR_FAIL_* checks) put the failed condition in code and
	# the message in rationale. push_error("text") puts the text in code and
	# leaves rationale empty. Either way the message is the first of the two.
	var text: String = rationale if not rationale.is_empty() else code
	# For push_error() and push_warning() the file and line Godot passes are
	# its own C++ location, the same for every call, so they say nothing about
	# the bug. The top frame of the script backtrace is where the game raised
	# it; fall back to the engine's location only when there is no backtrace.
	var where: String = _location(file, line, function)
	if not script_backtraces.is_empty():
		var backtrace: ScriptBacktrace = script_backtraces[0]
		if not backtrace.is_empty():
			where = _location(backtrace.get_frame_file(0), backtrace.get_frame_line(0), backtrace.get_frame_function(0))
	_append(_errors, "%s %s: %s (at %s)" % [_clock(), _type_name(error_type), text, where])


func _append(history: Array[String], entry: String) -> void:
	_mutex.lock()
	history.append(entry)
	while history.size() > _max_entries:
		history.remove_at(0)
	_mutex.unlock()


static func _clock() -> String:
	return Time.get_time_string_from_system()


static func _location(file: String, line: int, function: String) -> String:
	return "%s:%d in %s" % [file, line, function]


static func _type_name(error_type: int) -> String:
	match error_type:
		ERROR_TYPE_WARNING:
			return "WARNING"
		ERROR_TYPE_SCRIPT:
			return "SCRIPT ERROR"
		ERROR_TYPE_SHADER:
			return "SHADER ERROR"
		_:
			return "ERROR"
