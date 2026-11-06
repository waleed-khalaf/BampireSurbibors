extends GdUnitTestSuite
## Dowry Uncles arriving and chasing Shireen, checked through the Run seam
## (ADR-0001): build a Run, step it, look at the snapshot.

## Calibrated once on the user's machine (2026-11-06, Godot 4.7.2 headless,
## run_tests.cmd): a step with 300 Uncles packed around Shireen took about
## 850 µs on average (MEASURED_STEP_USEC). The budget allows about 3× that for
## noisy runs and is 15% of a 60 Hz frame (16,667 µs), leaving the rest for
## weapons, pickups and drawing. The test prints the time it measured; if it
## fails, find out what got slower before raising the budget.
const MEASURED_STEP_USEC: float = 850.0
const STEP_BUDGET_USEC: float = 2500.0


func _stand(run: Run, ticks: int) -> void:
	for i: int in ticks:
		run.step(Run.TIMESTEP, Vector2.ZERO)


## The visible screen while the camera sits on Shireen.
func _screen_around(shireen_position: Vector2) -> Rect2:
	return Rect2(shireen_position - RunConfig.DEFAULT_PLAY_AREA / 2.0, RunConfig.DEFAULT_PLAY_AREA)


## How far [param point] is outside [param rect] (0 if inside).
func _distance_outside(rect: Rect2, point: Vector2) -> float:
	var dx: float = maxf(maxf(rect.position.x - point.x, point.x - rect.end.x), 0.0)
	var dy: float = maxf(maxf(rect.position.y - point.y, point.y - rect.end.y), 0.0)
	return Vector2(dx, dy).length()


func test_uncles_spawn_off_screen_while_shireen_walks_around() -> void:
	var run := Run.new(RunConfig.new(TestContent.steady_uncles(10.0), 7))
	var directions: Array[Vector2] = [Vector2.RIGHT, Vector2(1, 1), Vector2.UP, Vector2.ZERO, Vector2.LEFT]
	var seen: Dictionary[int, bool] = {}
	var margin: float = TestContent.real().spawn_ramp.spawn_margin

	for i: int in 20 * Run.STEPS_PER_SECOND:
		@warning_ignore("integer_division")
		run.step(Run.TIMESTEP, directions[(i / 90) % directions.size()])
		var snapshot := run.snapshot()
		var screen: Rect2 = _screen_around(snapshot.shireen_position)
		for admirer: AdmirerSnapshot in snapshot.admirers:
			if seen.has(admirer.id):
				continue
			seen[admirer.id] = true
			# Off-screen by at least the spawn margin, so even his head stays
			# out of view.
			assert_float(_distance_outside(screen, admirer.position)).is_greater_equal(margin - 0.001)

	# 10 per second for 20 seconds. Summing 10/60 per step 1200 times lands a
	# hair under 200 in floating point, so the last one may be a step late.
	assert_int(seen.size()).is_between(199, 200)


## The ring is all around her, not just one side.
func test_uncles_arrive_from_every_side() -> void:
	var run := Run.new(RunConfig.new(TestContent.uncle_crowd(200), 3))
	var sides: Dictionary[String, int] = {"left": 0, "right": 0, "above": 0, "below": 0}
	var seen: Dictionary[int, bool] = {}

	for i: int in 2 * Run.STEPS_PER_SECOND:
		run.step(Run.TIMESTEP, Vector2.ZERO)
		for admirer: AdmirerSnapshot in run.snapshot().admirers:
			if seen.has(admirer.id):
				continue
			seen[admirer.id] = true
			if admirer.position.x < -320: sides.left += 1
			if admirer.position.x > 320: sides.right += 1
			if admirer.position.y < -180: sides.above += 1
			if admirer.position.y > 180: sides.below += 1

	assert_int(seen.size()).is_equal(200)
	for side: String in sides:
		assert_int(sides[side]).override_failure_message("no Uncles arrived %s" % side).is_greater(10)


func test_more_and_more_uncles_arrive_as_the_run_goes_on() -> void:
	var run := Run.new(RunConfig.new(TestContent.real(), 11))

	_stand(run, 60 * Run.STEPS_PER_SECOND)
	var first_minute: int = run.snapshot().admirer_count
	_stand(run, 60 * Run.STEPS_PER_SECOND)
	var second_minute: int = run.snapshot().admirer_count - first_minute

	# The real ramp: 1 per second at 0:00, +1 per second each minute. So
	# about 90 in the first minute and 150 in the second.
	assert_int(first_minute).is_between(89, 91)
	assert_int(second_minute).is_between(149, 151)


func test_the_crowd_stops_growing_at_the_cap() -> void:
	var run := Run.new(RunConfig.new(TestContent.steady_uncles(50.0, 120), 5))

	_stand(run, 10 * Run.STEPS_PER_SECOND)

	assert_int(run.snapshot().admirer_count).is_equal(120)


func test_an_uncle_walks_straight_at_shireen_at_his_speed() -> void:
	var run := Run.new(RunConfig.new(TestContent.uncle_crowd(1), 9))
	run.step(Run.TIMESTEP, Vector2.ZERO)
	var start: Vector2 = run.snapshot().admirers[0].position

	_stand(run, 2 * Run.STEPS_PER_SECOND)

	var uncle: AdmirerSnapshot = run.snapshot().admirers[0]
	# The real Uncle walks 40 px/s: 80 px closer after 2 seconds...
	assert_float(start.length() - uncle.position.length()).is_equal_approx(80.0, 0.01)
	# ...along the straight line from where he started to her, facing her.
	assert_vector(uncle.position.normalized()).is_equal_approx(start.normalized(), Vector2(0.0001, 0.0001))
	assert_vector(uncle.facing).is_equal_approx(-start.normalized(), Vector2(0.0001, 0.0001))


func test_uncles_close_the_distance_and_crowd_around_shireen() -> void:
	var run := Run.new(RunConfig.new(TestContent.uncle_crowd(30), 21))

	# The far corners of the ring are ~400 px away; at 40 px/s that's 10 s.
	_stand(run, 15 * Run.STEPS_PER_SECOND)

	for admirer: AdmirerSnapshot in run.snapshot().admirers:
		assert_float(admirer.position.length()).is_less(60.0)


func test_uncles_follow_shireen_when_she_walks_away() -> void:
	var run := Run.new(RunConfig.new(TestContent.uncle_crowd(1), 4))
	run.step(Run.TIMESTEP, Vector2.ZERO)
	_stand(run, 10 * Run.STEPS_PER_SECOND)

	# She walks right for 2 s (180 px). He turns and follows her.
	for i: int in 2 * Run.STEPS_PER_SECOND:
		run.step(Run.TIMESTEP, Vector2.RIGHT)

	var snapshot := run.snapshot()
	assert_float(snapshot.admirers[0].facing.x).is_greater(0.5)


func test_a_dense_crowd_spreads_out_instead_of_stacking() -> void:
	var run := Run.new(RunConfig.new(TestContent.uncle_crowd(150), 13))
	# 1.5 s for all of them to arrive, ~10 s to walk in from the far corners,
	# and some more to press in around her.
	_stand(run, 20 * Run.STEPS_PER_SECOND)

	var admirers: Array[AdmirerSnapshot] = run.snapshot().admirers
	var radius: float = TestContent.real_uncle().body_radius
	var shireen_radius: float = TestContent.real().shireen.body_radius
	var closest: float = INF
	for i: int in admirers.size():
		# Nobody stands on Shireen: at most a pixel into her body.
		assert_float(admirers[i].position.length()).is_greater(shireen_radius + radius - 1.0)
		for j: int in range(i + 1, admirers.size()):
			closest = minf(closest, admirers[i].position.distance_to(admirers[j].position))
	# Two Uncles touch when 14 px apart. In the crush, nobody overlaps
	# another by more than 10% of that.
	assert_float(closest).is_greater_equal(2.0 * radius * 0.9)
	# And it really is a crush: 150 Uncles packed perfectly would fill a disc
	# of about 90 px radius. Everyone stands within 140 px of her.
	var farthest: float = 0.0
	for admirer: AdmirerSnapshot in admirers:
		farthest = maxf(farthest, admirer.position.length())
	assert_float(farthest).is_less(140.0)


func test_three_hundred_uncles_step_within_the_time_budget() -> void:
	var run := Run.new(RunConfig.new(TestContent.uncle_crowd(300), 17))
	# Let them all arrive (3 s) and pack in first: a dense crowd is the slow
	# case for separation.
	_stand(run, 15 * Run.STEPS_PER_SECOND)
	assert_int(run.snapshot().admirer_count).is_equal(300)

	const MEASURED_STEPS: int = 300
	var directions: Array[Vector2] = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]
	var started: int = Time.get_ticks_usec()
	for i: int in MEASURED_STEPS:
		@warning_ignore("integer_division")
		run.step(Run.TIMESTEP, directions[(i / 60) % directions.size()])
	var average_usec: float = float(Time.get_ticks_usec() - started) / MEASURED_STEPS

	print("300 admirers: %.0f µs per step (calibrated at %.0f, budget %.0f)" % [average_usec, MEASURED_STEP_USEC, STEP_BUDGET_USEC])
	assert_float(average_usec).is_less(STEP_BUDGET_USEC)


## The seed decides where admirers arrive, and nothing else does: the same
## seed gives the same crowd, a different seed a different one.
func test_the_seed_decides_where_uncles_arrive() -> void:
	var first := Run.new(RunConfig.new(TestContent.real(), 99))
	var same := Run.new(RunConfig.new(TestContent.real(), 99))
	var other := Run.new(RunConfig.new(TestContent.real(), 100))

	for run: Run in [first, same, other]:
		_stand(run, 5 * Run.STEPS_PER_SECOND)

	assert_dict(same.snapshot().to_dict()).is_equal(first.snapshot().to_dict())
	assert_dict(other.snapshot().to_dict()).is_not_equal(first.snapshot().to_dict())


func test_the_snapshot_counts_the_admirers() -> void:
	var run := Run.new(RunConfig.new(TestContent.uncle_crowd(25), 1))
	_stand(run, Run.STEPS_PER_SECOND)

	var snapshot := run.snapshot()
	assert_int(snapshot.admirer_count).is_equal(25)
	assert_int(snapshot.to_dict()["admirer_count"]).is_equal(25)
	assert_str(snapshot.admirers[0].type_id).is_equal("dowry_uncle")
