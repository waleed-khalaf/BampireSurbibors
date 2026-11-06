extends GdUnitTestSuite
## Debug capture files are named by date and time, and the rolling folder
## keeps only the newest screenshots.


func test_timestamps_sort_in_time_order() -> void:
	var name: String = CaptureFiles.timestamp_name({
		"year": 2026, "month": 11, "day": 6, "hour": 9, "minute": 5, "second": 3,
	})

	assert_str(name).is_equal("2026-11-06_09-05-03")


func test_reasons_become_safe_file_names() -> void:
	assert_str(CaptureFiles.slug("f12")).is_equal("f12")
	assert_str(CaptureFiles.slug("Run ended!")).is_equal("run-ended")
	assert_str(CaptureFiles.slug("  script / error  ")).is_equal("script-error")
	assert_str(CaptureFiles.slug("???")).is_equal("capture")


func test_an_existing_name_gets_a_number() -> void:
	var folder: String = ProjectSettings.globalize_path(create_temp_dir("unused_path"))
	var taken: String = folder.path_join("shot.png")
	FileAccess.open(taken, FileAccess.WRITE).store_string("x")

	assert_str(CaptureFiles.unused_path(taken)).is_equal(folder.path_join("shot_2.png"))
	assert_str(CaptureFiles.unused_path(folder.path_join("free.png"))).is_equal(folder.path_join("free.png"))


func test_the_rolling_folder_keeps_the_newest_60() -> void:
	var folder: String = ProjectSettings.globalize_path(create_temp_dir("rolling"))
	for second: int in 65:
		@warning_ignore("integer_division")
		var name: String = CaptureFiles.timestamp_name({
			"year": 2026, "month": 11, "day": 6, "hour": 12, "minute": second / 60, "second": second % 60,
		})
		FileAccess.open(folder.path_join(name + ".png"), FileAccess.WRITE).store_string("x")

	var deleted: int = CaptureFiles.keep_newest(folder, "png", 60)

	var left: PackedStringArray = DirAccess.get_files_at(folder)
	assert_int(deleted).is_equal(5)
	assert_int(left.size()).is_equal(60)
	assert_array(Array(left)).not_contains(["2026-11-06_12-00-04.png"])
	assert_array(Array(left)).contains(["2026-11-06_12-00-05.png", "2026-11-06_12-01-04.png"])


func test_clean_up_leaves_other_files_alone() -> void:
	var folder: String = ProjectSettings.globalize_path(create_temp_dir("rolling_other"))
	FileAccess.open(folder.path_join("notes.txt"), FileAccess.WRITE).store_string("x")
	FileAccess.open(folder.path_join("a.png"), FileAccess.WRITE).store_string("x")

	CaptureFiles.keep_newest(folder, "png", 0)

	assert_array(Array(DirAccess.get_files_at(folder))).contains_exactly(["notes.txt"])
