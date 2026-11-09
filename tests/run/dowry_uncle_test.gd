extends GdUnitTestSuite
## Dowry Uncles arriving and chasing Shireen, checked through the Run seam
## (ADR-0001): build a Run, step it, look at the snapshot.
##
## The Uncles here are harmless (TestContent.harmless_uncle): they move
## exactly like the real ones but drain no Patience, so a run lasts as long as
## a test needs. What a touch costs is in patience_test.gd.

## Calibrated on the user's machine (2026-11-06, Godot 4.7.2 headless via
## run_tests.cmd). The timing tests measure what the view pays every frame: a
## step plus the snapshot after it (RunView), since the snapshot copies every
## admirer. With 300 Uncles packed around Shireen that pair took 1,030–1,230 µs
## over a dozen runs, most of them near 1,080 (about 760 for the step and 320
## for the snapshot), with one spike to 1,840 while the machine was busy; the
## strung-out crowd below took 1,005–1,230 µs. Ticket 05 then added the touch
## check and the Patience drain to every step: about 90 µs more with 300
## Uncles (2026-11-09, on a day the machine ran slower overall: ~1,260 µs with
## the code before it, ~1,350 after). MEASURED_STEP_USEC is the typical value
## from the first calibration plus that share. The budget allows about 3× the
## first calibration for noisy runs and is 20% of a 60 Hz frame (16,667 µs),
## leaving the rest for weapons, pickups and drawing. The tests print the time
## they measured; if one fails, find out what got slower before raising the
## budget.
const MEASURED_STEP_USEC: float = 1200.0
const STEP_BUDGET_USEC: float = 3300.0


func _stand(run: Run, ticks: int) -> void:
	for i: int in ticks:
		run.step(Run.TIMESTEP, Vector2.ZERO)


## Times [param steps] steps the way the view takes them (RunView): a step,
## then a snapshot, every tick. The pair is measured rather than the step
## alone because the snapshot copies every admirer and the game pays for it
## every frame. Shireen walks the [param directions] in turn, a second each.
## Returns the average per tick in microseconds.
func _average_usec_per_step_and_snapshot(run: Run, steps: int, directions: Array[Vector2]) -> float:
	var started: int = Time.get_ticks_usec()
	for i: int in steps:
		@warning_ignore("integer_division")
		run.step(Run.TIMESTEP, directions[(i / Run.STEPS_PER_SECOND) % directions.size()])
		run.snapshot()
	return float(Time.get_ticks_usec() - started) / steps


## The visible screen while the camera sits on Shireen.
func _screen_around(shireen_position: Vector2) -> Rect2:
	return Rect2(shireen_position - RunConfig.DEFAULT_PLAY_AREA / 2.0, RunConfig.DEFAULT_PLAY_AREA)


## How far [param point] is outside [param rect] (0 if inside).
func _distance_outside(rect: Rect2, point: Vector2) -> float:
	var dx: float = maxf(maxf(rect.position.x - point.x, point.x - rect.end.x), 0.0)
	var dy: float = maxf(maxf(rect.position.y - point.y, point.y - rect.end.y), 0.0)
	return Vector2(dx, dy).length()


func test_uncles_spawn_off_screen_while_shireen_walks_around() -> void:
	var content := TestContent.steady_harmless_uncles(10.0)
	var run := Run.new(RunConfig.new(content, 7))
	var directions: Array[Vector2] = [Vector2.RIGHT, Vector2(1, 1), Vector2.UP, Vector2.ZERO, Vector2.LEFT]
	var seen: Dictionary[int, bool] = {}
	# The margin of the ramp this Run was built with, not the real
	# content/spawn_ramp.tres: tuning that file must not fail this test.
	var margin: float = content.spawn_ramp.spawn_margin

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
	var run := Run.new(RunConfig.new(TestContent.harmless_uncle_crowd(200), 3))
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
	var run := Run.new(RunConfig.new(TestContent.real_with_harmless_uncles(), 11))

	_stand(run, 60 * Run.STEPS_PER_SECOND)
	var first_minute: int = run.snapshot().admirer_count
	_stand(run, 60 * Run.STEPS_PER_SECOND)
	var second_minute: int = run.snapshot().admirer_count - first_minute

	# The real ramp: 1 per second at 0:00, +1 per second each minute. So
	# about 90 in the first minute and 150 in the second.
	assert_int(first_minute).is_between(89, 91)
	assert_int(second_minute).is_between(149, 151)


func test_the_crowd_stops_growing_at_the_cap() -> void:
	var run := Run.new(RunConfig.new(TestContent.steady_harmless_uncles(50.0, 120), 5))

	_stand(run, 10 * Run.STEPS_PER_SECOND)

	assert_int(run.snapshot().admirer_count).is_equal(120)


func test_an_uncle_walks_straight_at_shireen_at_his_speed() -> void:
	var run := Run.new(RunConfig.new(TestContent.harmless_uncle_crowd(1), 9))
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
	var run := Run.new(RunConfig.new(TestContent.harmless_uncle_crowd(30), 21))

	# The far corners of the ring are ~400 px away; at 40 px/s that's 10 s.
	_stand(run, 15 * Run.STEPS_PER_SECOND)

	for admirer: AdmirerSnapshot in run.snapshot().admirers:
		assert_float(admirer.position.length()).is_less(60.0)


func test_uncles_follow_shireen_when_she_walks_away() -> void:
	var run := Run.new(RunConfig.new(TestContent.harmless_uncle_crowd(1), 4))
	run.step(Run.TIMESTEP, Vector2.ZERO)
	_stand(run, 10 * Run.STEPS_PER_SECOND)

	# She walks right for 2 s (180 px). He turns and follows her.
	for i: int in 2 * Run.STEPS_PER_SECOND:
		run.step(Run.TIMESTEP, Vector2.RIGHT)

	var snapshot := run.snapshot()
	assert_float(snapshot.admirers[0].facing.x).is_greater(0.5)


func test_a_dense_crowd_spreads_out_instead_of_stacking() -> void:
	var run := Run.new(RunConfig.new(TestContent.harmless_uncle_crowd(150), 13))
	# 1.5 s for all of them to arrive, ~10 s to walk in from the far corners,
	# and some more to press in around her.
	_stand(run, 20 * Run.STEPS_PER_SECOND)

	var admirers: Array[AdmirerSnapshot] = run.snapshot().admirers
	var radius: float = TestContent.real_uncle().body_radius
	var shireen_radius: float = TestContent.real().shireen.body_radius
	var closest: float = INF
	for i: int in admirers.size():
		# Nobody stands on Shireen. The keep-out is the last thing done to each
		# admirer in a step, so everyone ends it on or outside her edge; the
		# 0.001 only covers float rounding.
		assert_float(admirers[i].position.length()).is_greater_equal(shireen_radius + radius - 0.001)
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
	var run := Run.new(RunConfig.new(TestContent.harmless_uncle_crowd(300), 17))
	# Let them all arrive (3 s) and pack in first: a dense crowd is the slow
	# case for separation.
	_stand(run, 15 * Run.STEPS_PER_SECOND)
	assert_int(run.snapshot().admirer_count).is_equal(300)

	var directions: Array[Vector2] = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]
	var average_usec: float = _average_usec_per_step_and_snapshot(run, 300, directions)

	print("300 admirers: %.0f µs per step and snapshot (calibrated at %.0f, budget %.0f)" % [average_usec, MEASURED_STEP_USEC, STEP_BUDGET_USEC])
	assert_float(average_usec).is_less(STEP_BUDGET_USEC)


## The slow case the test above can't see. Shireen walks away from the Uncles,
## who follow at only 40 px/s, for a long time, so the first Uncles end up
## thousands of pixels behind the newest. Then she stops: the Uncles still
## arriving pack in around her within seconds, while the stragglers take
## minutes to catch up. A grid whose cells grow with the crowd's extent then
## puts the whole packed crowd into a few cells, and every packed admirer
## compares against nearly all the others instead of his few neighbors.
##
## The real Shireen (90 px/s) strings the crowd out by only 50 px per second,
## so she would have to walk for three minutes. To keep the test quick a
## stand-in walks at the fastest speed the content allows (400 px/s), and the
## spawn ramp starts from zero so that few Uncles arrive during the walk and
## most of them after she stops. The Uncles move like the real ones.
func test_a_strung_out_crowd_pressing_in_steps_within_the_time_budget() -> void:
	var content := TestContent.harmless_uncles_chasing(TestContent.shireen_with_speed(400.0), 0.0, 6.0, 300)
	var run := Run.new(RunConfig.new(content, 23))
	# 40 s of sprinting leaves ~80 Uncles strung out over ~12,000 px...
	for i: int in 40 * Run.STEPS_PER_SECOND:
		run.step(Run.TIMESTEP, Vector2.RIGHT)
	# ...and 40 s of standing lets the other ~220 arrive and pack in around
	# her, while the stragglers have closed only 1,600 px of that gap.
	_stand(run, 40 * Run.STEPS_PER_SECOND)

	# Check the scene really is what the test is about: the cap of 300 is
	# reached, most of them are packed around her, and the stragglers are
	# still thousands of pixels away.
	var snapshot := run.snapshot()
	var packed: int = 0
	var farthest: float = 0.0
	for admirer: AdmirerSnapshot in snapshot.admirers:
		var distance: float = admirer.position.distance_to(snapshot.shireen_position)
		if distance < 150.0:
			packed += 1
		farthest = maxf(farthest, distance)
	assert_int(snapshot.admirer_count).is_equal(300)
	assert_int(packed).is_greater(150)
	assert_float(farthest).is_greater(8000.0)

	var average_usec: float = _average_usec_per_step_and_snapshot(run, 120, [Vector2.ZERO])

	print("strung-out crowd, %d packed, stragglers %.0f px behind: %.0f µs per step and snapshot (budget %.0f)" % [packed, farthest, average_usec, STEP_BUDGET_USEC])
	assert_float(average_usec).is_less(STEP_BUDGET_USEC)


## The seed decides where admirers arrive, and nothing else does: the same
## seed gives the same crowd, a different seed a different one.
func test_the_seed_decides_where_uncles_arrive() -> void:
	var first := Run.new(RunConfig.new(TestContent.real_with_harmless_uncles(), 99))
	var same := Run.new(RunConfig.new(TestContent.real_with_harmless_uncles(), 99))
	var other := Run.new(RunConfig.new(TestContent.real_with_harmless_uncles(), 100))

	for run: Run in [first, same, other]:
		_stand(run, 5 * Run.STEPS_PER_SECOND)

	assert_dict(same.snapshot().to_dict()).is_equal(first.snapshot().to_dict())
	assert_dict(other.snapshot().to_dict()).is_not_equal(first.snapshot().to_dict())


func test_the_snapshot_counts_the_admirers() -> void:
	var run := Run.new(RunConfig.new(TestContent.harmless_uncle_crowd(25), 1))
	_stand(run, Run.STEPS_PER_SECOND)

	var snapshot := run.snapshot()
	assert_int(snapshot.admirer_count).is_equal(25)
	assert_int(snapshot.to_dict()["admirer_count"]).is_equal(25)
	assert_str(snapshot.admirers[0].type_id).is_equal("dowry_uncle")
