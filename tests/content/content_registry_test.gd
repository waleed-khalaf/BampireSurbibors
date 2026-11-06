extends GdUnitTestSuite
## The content registry loads content data from Resource files and rejects
## broken content with a message a designer can act on.

const NOT_SHIREEN_PATH: String = "res://tests/content/fixtures/not_shireen.tres"
const MISSING_PATH: String = "res://tests/content/fixtures/does_not_exist.tres"
const UNREADABLE_PATH: String = "res://tests/content/fixtures/unreadable.tres"


func test_the_real_content_passes_validation() -> void:
	var content := ContentRegistry.load_default()

	assert_array(content.errors).is_empty()
	assert_bool(content.is_valid()).is_true()


func test_the_real_content_gives_shireen_90_pixels_per_second() -> void:
	# The design doc's starting value (design §4).
	assert_float(ContentRegistry.load_default().shireen.move_speed).is_equal(90.0)


func test_a_shireen_who_cannot_move_is_rejected() -> void:
	var content := ContentRegistry.from_data(TestContent.shireen_with_speed(0.0))

	assert_bool(content.is_valid()).is_false()
	assert_array(content.errors).contains_exactly([
		"Shireen: move_speed must be between 10 and 400 px/s, but it is 0.",
	])


func test_an_absurdly_fast_shireen_is_rejected() -> void:
	var content := ContentRegistry.from_data(TestContent.shireen_with_speed(5000.0))

	assert_array(content.errors).contains_exactly([
		"Shireen: move_speed must be between 10 and 400 px/s, but it is 5000.",
	])


func test_a_missing_data_file_is_rejected_with_its_path() -> void:
	var content := ContentRegistry.load_from(MISSING_PATH)

	assert_bool(content.is_valid()).is_false()
	assert_array(content.errors).contains_exactly([
		"Shireen: no data file at %s." % MISSING_PATH,
	])


func test_a_data_file_of_the_wrong_type_is_rejected() -> void:
	var content := ContentRegistry.load_from(NOT_SHIREEN_PATH)

	assert_array(content.errors).contains_exactly([
		"Shireen: %s is a Gradient, not ShireenData. Its script should be res://src/content/shireen_data.gd." % NOT_SHIREEN_PATH,
	])


## A hand-edit typo leaves a file Godot can't parse. That must be a message,
## not a crash.
func test_a_data_file_godot_cannot_read_is_rejected() -> void:
	var content := ContentRegistry.load_from(UNREADABLE_PATH)

	assert_array(content.errors).contains_exactly([
		"Shireen: %s could not be read. Open it in Godot to see what is wrong with it." % UNREADABLE_PATH,
	])


# --- Admirers ---------------------------------------------------------------

func _uncle() -> AdmirerData:
	var uncle := AdmirerData.new()
	uncle.id = &"dowry_uncle"
	return uncle


func _content_with(admirers: Array[AdmirerData], spawns: SpawnRampData = null) -> ContentRegistry:
	return ContentRegistry.from_data(TestContent.shireen_with_speed(90.0), admirers, spawns)


func test_the_real_dowry_uncle_has_the_design_numbers() -> void:
	# Design §7: HP 30, speed 40, drain 10/s, cash 2, walks straight at you.
	var uncle: AdmirerData = ContentRegistry.load_default().admirers[&"dowry_uncle"]

	assert_float(uncle.max_hp).is_equal(30.0)
	assert_float(uncle.move_speed).is_equal(40.0)
	assert_float(uncle.drain_per_second).is_equal(10.0)
	assert_int(uncle.cash).is_equal(2)
	assert_str(uncle.behavior_id).is_equal("chase")


func test_a_behavior_is_chosen_by_its_id() -> void:
	var content := ContentRegistry.load_default()

	var behavior: AdmirerBehavior = content.create_admirer_behavior(content.admirers[&"dowry_uncle"])

	assert_bool(behavior is ChaseBehavior).is_true()


func test_the_real_spawn_ramp_brings_dowry_uncles() -> void:
	assert_str(ContentRegistry.load_default().spawn_ramp.admirer_id).is_equal("dowry_uncle")


func test_an_unknown_behavior_id_is_rejected() -> void:
	var uncle := _uncle()
	uncle.behavior_id = &"moonwalk"

	assert_array(_content_with([uncle]).errors).contains_exactly([
		"Admirer dowry_uncle: behavior_id \"moonwalk\" is not a known behavior. Known behaviors: chase.",
	])


func test_a_spawn_ramp_for_an_unknown_admirer_is_rejected() -> void:
	var spawns := TestContent.steady_spawns(&"dowry_aunt", 1.0, 10)

	assert_array(_content_with([_uncle()], spawns).errors).contains_exactly([
		"Spawn ramp: admirer_id \"dowry_aunt\" is not an admirer type. Known types: dowry_uncle.",
	])


func test_an_admirer_who_cannot_move_is_rejected() -> void:
	var uncle := _uncle()
	uncle.move_speed = 0.0

	assert_array(_content_with([uncle]).errors).contains_exactly([
		"Admirer dowry_uncle: move_speed must be between 10 and 400 px/s, but it is 0.",
	])


func test_two_admirer_types_with_the_same_id_are_rejected() -> void:
	assert_array(_content_with([_uncle(), _uncle()]).errors).contains_exactly([
		"Admirer dowry_uncle: the id is used by more than one admirer type. Each needs its own.",
	])


func test_a_missing_admirer_folder_is_rejected() -> void:
	var content := ContentRegistry.load_from(ContentRegistry.SHIREEN_PATH, "res://tests/content/fixtures/no_admirers_here", ContentRegistry.SPAWN_RAMP_PATH)

	# The spawn ramp then also names an admirer that doesn't exist.
	assert_array(content.errors).contains_exactly([
		"Admirers: no admirer data files in res://tests/content/fixtures/no_admirers_here.",
		"Spawn ramp: admirer_id \"dowry_uncle\" is not an admirer type. Known types: (none).",
	])
