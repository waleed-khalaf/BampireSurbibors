extends GdUnitTestSuite
## Shireen's movement and facing, checked through the Run seam (ADR-0001).
## Most tests use a purpose-built Shireen with a round speed of 100 px/s so
## the expected distances are easy to read.


## A content set whose only change from the real one is Shireen's speed.
func _content_with_speed(move_speed: float) -> ContentRegistry:
	var shireen := ShireenData.new()
	shireen.move_speed = move_speed
	return ContentRegistry.from_data(shireen)


func _run_with_speed(move_speed: float) -> Run:
	return Run.new(RunConfig.new(1, RunConfig.DEFAULT_PLAY_AREA, _content_with_speed(move_speed)))


func _walk(run: Run, direction: Vector2, ticks: int) -> void:
	for i: int in ticks:
		run.step(Run.TIMESTEP, direction)


func test_shireen_walks_her_data_speed_in_pixels_per_second() -> void:
	var run := _run_with_speed(100.0)

	_walk(run, Vector2.RIGHT, Run.STEPS_PER_SECOND)

	assert_vector(run.snapshot().shireen_position).is_equal_approx(Vector2(100, 0), Vector2(0.001, 0.001))


## The Run normalizes the direction itself, so even a raw (1, 1) input can't
## make her faster on the diagonal: 100 px along the diagonal, not 141.
func test_walking_diagonally_is_not_faster() -> void:
	var run := _run_with_speed(100.0)

	_walk(run, Vector2(1, 1), Run.STEPS_PER_SECOND)

	var position: Vector2 = run.snapshot().shireen_position
	assert_float(position.length()).is_equal_approx(100.0, 0.001)
	assert_vector(position).is_equal_approx(Vector2(70.711, 70.711), Vector2(0.001, 0.001))


func test_shireen_keeps_facing_her_last_direction_after_she_stops() -> void:
	var run := _run_with_speed(100.0)

	_walk(run, Vector2(-1, -1), 30)
	_walk(run, Vector2.ZERO, 30)

	var snapshot := run.snapshot()
	assert_vector(snapshot.shireen_facing).is_equal_approx(Vector2(-0.7071, -0.7071), Vector2(0.0001, 0.0001))
	assert_bool(snapshot.shireen_moving).is_false()
