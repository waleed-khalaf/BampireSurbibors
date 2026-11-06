extends GdUnitTestSuite
## The debug capture service writes a bug snapshot folder with a state.txt
## built from the state providers and the recent log. Screenshots need a
## window, so they are checked by playing (F5) instead; this suite runs
## headless and covers everything else.

const DebugCaptureScript: GDScript = preload("res://src/debug/debug_capture.gd")

var _folder: String


func before_test() -> void:
	_folder = ProjectSettings.globalize_path(create_temp_dir("debug_captures"))


## A capture service of its own, writing into a temporary folder, so the
## tests never touch the real debug_captures/ or the global autoload.
func _service() -> Node:
	var service: Node = auto_free(DebugCaptureScript.new())
	service.root_folder = _folder
	service.rolling_enabled = false
	add_child(service)
	return service


func _read_state(capture_folder: String) -> String:
	return FileAccess.get_file_as_string(capture_folder.path_join("state.txt"))


func test_a_started_service_tells_godot_to_ignore_its_capture_folder() -> void:
	_service()

	# Without this marker the editor imports every screenshot as a texture.
	assert_bool(FileAccess.file_exists(_folder.path_join(".gdignore"))).is_true()


func test_a_capture_puts_the_ignore_marker_back_after_the_folder_was_deleted() -> void:
	var service: Node = _service()
	var marker: String = _folder.path_join(".gdignore")
	DirAccess.remove_absolute(marker)
	DirAccess.remove_absolute(_folder)
	assert_bool(DirAccess.dir_exists_absolute(_folder)).is_false()

	service.capture("f12")

	assert_bool(FileAccess.file_exists(marker)).is_true()


func test_a_snapshot_is_a_folder_named_by_date_time_and_reason() -> void:
	var folder: String = _service().capture("Run ended")

	assert_str(folder.get_base_dir()).is_equal(_folder)
	assert_bool(RegEx.create_from_string("^\\d{4}-\\d\\d-\\d\\d_\\d\\d-\\d\\d-\\d\\d_run-ended$").search(folder.get_file()) != null) \
		.override_failure_message("unexpected folder name: " + folder.get_file()).is_true()
	assert_bool(FileAccess.file_exists(folder.path_join("state.txt"))).is_true()


func test_state_txt_records_the_reason_fps_and_screenshot() -> void:
	var state: String = _read_state(_service().capture("f12"))

	assert_str(state).contains("reason: f12")
	assert_str(state).contains("fps: ")
	# The suite runs headless, so there's nothing to screenshot.
	assert_str(state).contains("screenshot: none (no window: headless run)")


func test_two_snapshots_in_the_same_second_are_both_kept() -> void:
	var service: Node = _service()

	var first: String = service.capture("f12")
	var second: String = service.capture("f12")

	assert_str(second).is_not_equal(first)
	assert_bool(FileAccess.file_exists(first.path_join("state.txt"))).is_true()
	assert_bool(FileAccess.file_exists(second.path_join("state.txt"))).is_true()


func test_a_new_system_adds_its_state_through_a_provider() -> void:
	var service: Node = _service()
	service.register_provider("Patience", func() -> Dictionary:
		return {"patience": 75.0, "max_patience": 100})
	service.register_provider("Weapon", func() -> Dictionary:
		return {"weapon": "zills", "abilities": ["chime_ring"]})

	var state: String = _read_state(service.capture("f12"))

	assert_str(state).contains("== Patience ==\npatience: 75.00\nmax_patience: 100\n")
	assert_str(state).contains("== Weapon ==\nweapon: zills\nabilities: [\"chime_ring\"]\n")
	# Sections keep the order they were registered in.
	assert_int(state.find("== Patience ==")).is_less(state.find("== Weapon =="))


func test_providers_are_read_at_capture_time() -> void:
	var service: Node = _service()
	var admirers: Array[int] = [3]
	service.register_provider("Admirers", func() -> Dictionary: return {"count": admirers[0]})

	admirers[0] = 42
	var state: String = _read_state(service.capture("f12"))

	assert_str(state).contains("count: 42")


func test_positions_are_written_to_one_decimal() -> void:
	var service: Node = _service()
	service.register_provider("Run", func() -> Dictionary:
		return {"shireen_position": Vector2(12.3456, -7.0)})

	assert_str(_read_state(service.capture("f12"))).contains("shireen_position: (12.3, -7.0)")


func test_an_unregistered_provider_is_left_out() -> void:
	var service: Node = _service()
	service.register_provider("Patience", func() -> Dictionary: return {"patience": 1})

	service.unregister_provider("Patience")
	var state: String = _read_state(service.capture("f12"))

	assert_str(state).not_contains("== Patience ==")
	assert_str(state).contains("(no state providers registered)")


func test_a_provider_whose_object_was_freed_is_reported_not_crashed_on() -> void:
	var service: Node = _service()
	var owner_node := Node.new()
	service.register_provider("Falcon", owner_node.get_child_count)
	owner_node.free()

	var state: String = _read_state(service.capture("f12"))

	assert_str(state).contains("== Falcon ==\n(provider is gone: its object was freed)")


func test_a_provider_that_returns_the_wrong_type_is_reported() -> void:
	var service: Node = _service()
	service.register_provider("Broken", func() -> int: return 7)

	assert_str(_read_state(service.capture("f12"))).contains("(provider returned int, expected a Dictionary)")


func test_state_txt_holds_the_last_20_log_lines() -> void:
	var service: Node = _service()
	for i: int in range(1, 26):
		print("capture test line %02d" % i)

	var state: String = _read_state(service.capture("f12"))

	assert_str(state).contains("capture test line 25")
	assert_str(state).contains("capture test line 06")
	assert_str(state).not_contains("capture test line 05")


func test_state_txt_holds_recent_warnings_apart_from_log_lines() -> void:
	var service: Node = _service()
	push_warning("capture test warning")
	for i: int in 30:
		print("noise %d" % i)

	var state: String = _read_state(service.capture("f12"))

	# 30 prints would push it out of a shared history; it has its own.
	var errors_section: String = state.substr(state.find("== Last 20 errors and warnings"))
	assert_str(errors_section).contains("WARNING: capture test warning")
