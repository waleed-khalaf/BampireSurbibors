extends GdUnitTestSuite
## Tests go through the Run seam only: build a Run from a config, feed it
## steps and inputs, then check the snapshot (ADR-0001).


## A fixed, varied input script so the tests exercise real input. Returns the
## move direction for a given tick.
func _scripted_input(tick: int) -> Vector2:
	var directions: Array[Vector2] = [
		Vector2.ZERO, Vector2.RIGHT, Vector2(1, 1).normalized(), Vector2.DOWN,
		Vector2.LEFT, Vector2.UP, Vector2(-1, -1).normalized(),
	]
	# Change direction every 20 ticks (1/3 s).
	@warning_ignore("integer_division")
	return directions[(tick / 20) % directions.size()]


func _play(run: Run, ticks: int) -> Array[Dictionary]:
	var snapshots: Array[Dictionary] = []
	for i: int in ticks:
		run.step(Run.TIMESTEP, _scripted_input(i))
		snapshots.append(run.snapshot().to_dict())
	return snapshots


func test_a_new_run_starts_at_zero() -> void:
	var run := Run.new(RunConfig.new(TestContent.real(), 1))

	assert_float(run.snapshot().time).is_equal(0.0)
	assert_int(run.snapshot().tick).is_equal(0)


func test_sixty_steps_make_one_second_of_run_time() -> void:
	var run := Run.new(RunConfig.new(TestContent.real(), 1))

	_play(run, Run.STEPS_PER_SECOND)

	assert_float(run.snapshot().time).is_equal_approx(1.0, 0.000001)
	assert_int(run.snapshot().tick).is_equal(60)


func test_five_minutes_of_steps_report_five_minutes_without_drift() -> void:
	# No admirers: this is about the clock, and simulating five minutes of a
	# 300-strong crowd would add ~10 s to every test run.
	var run := Run.new(RunConfig.new(TestContent.with_shireen_speed(90.0), 1))

	for i: int in 5 * 60 * Run.STEPS_PER_SECOND:
		run.step(Run.TIMESTEP, _scripted_input(i))

	assert_float(run.snapshot().time).is_equal_approx(300.0, 0.000001)


## Shireen's position and facing depend on the scripted input and the
## admirers' spawn points on the seed, so a Run that read anything outside its
## seed and inputs would drift apart here.
func test_the_same_seed_and_inputs_produce_identical_snapshots() -> void:
	var first := Run.new(RunConfig.new(TestContent.real(), 12345))
	var second := Run.new(RunConfig.new(TestContent.real(), 12345))

	var first_snapshots := _play(first, 10 * Run.STEPS_PER_SECOND)
	var second_snapshots := _play(second, 10 * Run.STEPS_PER_SECOND)

	# Every step must match, not just the final one.
	assert_int(first_snapshots.size()).is_equal(second_snapshots.size())
	for i: int in first_snapshots.size():
		assert_dict(first_snapshots[i]).is_equal(second_snapshots[i])


func test_a_snapshot_is_a_copy_that_does_not_change_the_run() -> void:
	var run := Run.new(RunConfig.new(TestContent.real(), 1))
	run.step(Run.TIMESTEP, Vector2.ZERO)

	var snapshot := run.snapshot()
	snapshot.time = 999.0
	snapshot.tick = 999

	assert_int(run.snapshot().tick).is_equal(1)
	assert_float(run.snapshot().time).is_equal_approx(Run.TIMESTEP, 0.000001)
