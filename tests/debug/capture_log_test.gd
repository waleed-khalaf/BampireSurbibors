extends GdUnitTestSuite
## The recent-errors history in state.txt exists to locate bugs, so each entry
## must point at the script line that raised it, not at the engine's own
## push_error()/push_warning() implementation.

const THIS_SCRIPT: String = "res://tests/debug/capture_log_test.gd"

var _log: CaptureLog


func before_test() -> void:
	# A CaptureLog of its own, registered like the DebugCapture autoload does,
	# so the test sees exactly what Godot hands a Logger.
	_log = CaptureLog.new(20)
	OS.add_logger(_log)


func after_test() -> void:
	OS.remove_logger(_log)
	_log = null


func test_a_warning_points_at_the_script_line_that_raised_it() -> void:
	push_warning("capture log test warning")

	var entry: String = _find_entry("capture log test warning")

	assert_str(entry).override_failure_message("the warning never reached recent_errors()").is_not_empty()
	assert_str(entry).contains("WARNING: capture log test warning")
	# Godot reports push_warning's own C++ location as file:line; that's the
	# same line for every warning in the game and says nothing about the bug.
	assert_str(entry).not_contains("variant_utility.cpp")
	assert_str(entry).contains("(at %s:" % THIS_SCRIPT)
	assert_str(entry).contains("in test_a_warning_points_at_the_script_line_that_raised_it)")


func _find_entry(text: String) -> String:
	for entry: String in _log.recent_errors():
		if entry.contains(text):
			return entry
	return ""
