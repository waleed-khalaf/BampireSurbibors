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
