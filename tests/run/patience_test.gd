extends GdUnitTestSuite
## Patience, its drain and "You said yes.", checked through the Run seam
## (ADR-0001): build a Run, step it, look at the snapshot and the events.


func _stand(run: Run, ticks: int) -> void:
	for i: int in ticks:
		run.step(Run.TIMESTEP, Vector2.ZERO)


## Stands still until Shireen first loses Patience, giving up after 15 s (an
## Uncle needs at most ~10 s to walk in from the far corner of the spawn ring).
func _stand_until_first_touch(run: Run) -> void:
	for i: int in 15 * Run.STEPS_PER_SECOND:
		run.step(Run.TIMESTEP, Vector2.ZERO)
		if run.snapshot().patience < run.snapshot().max_patience:
			return
	fail("nobody touched Shireen within 15 s")


func _touching_count(snapshot: RunSnapshot) -> int:
	var count: int = 0
	for admirer: AdmirerSnapshot in snapshot.admirers:
		if admirer.touching:
			count += 1
	return count


## Checks every step of [param seconds] of standing still: the Patience lost
## in the step is [param drain_per_second] for each admirer touching her.
## Returns the most admirers that touched her at once.
func _assert_each_touching_admirer_drains(run: Run, seconds: int, drain_per_second: float) -> int:
	var most_touching: int = 0
	var before: float = run.snapshot().patience
	for i: int in seconds * Run.STEPS_PER_SECOND:
		run.step(Run.TIMESTEP, Vector2.ZERO)
		var snapshot := run.snapshot()
		var touching: int = _touching_count(snapshot)
		var expected: float = touching * drain_per_second / Run.STEPS_PER_SECOND
		if absf(before - snapshot.patience - expected) > 0.0001:
			# One message, not one for each of the hundreds of steps after it.
			fail("step %d: %d touching should drain %f, but Patience went from %f to %f" % [i, touching, expected, before, snapshot.patience])
			return most_touching
		most_touching = maxi(most_touching, touching)
		before = snapshot.patience
	return most_touching


## Stands still until the run ends, giving up after 60 s. Returns the events
## of every step taken, in order.
func _stand_until_the_end(run: Run) -> Array[RunEvent]:
	var events: Array[RunEvent] = []
	for i: int in 60 * Run.STEPS_PER_SECOND:
		events.append_array(run.step(Run.TIMESTEP, Vector2.ZERO))
		if run.snapshot().phase == Run.Phase.ENDED:
			return events
	fail("the run did not end within 60 s")
	return events


## The run-ended event of a run stood through to its end.
func _ending_of(run: Run) -> RunEndedEvent:
	var events := _stand_until_the_end(run)
	return events.back() as RunEndedEvent


func test_a_new_run_starts_with_full_patience_from_the_data() -> void:
	# Design §4: Shireen starts with 100 Patience.
	var real := Run.new(RunConfig.new(TestContent.real(), 1))
	var patient := Run.new(RunConfig.new(TestContent.crowd(TestContent.real_uncle(), 1, TestContent.shireen_with_patience(250.0)), 1))

	assert_float(real.snapshot().patience).is_equal(100.0)
	assert_float(real.snapshot().max_patience).is_equal(100.0)
	assert_float(patient.snapshot().patience).is_equal(250.0)
	assert_float(patient.snapshot().max_patience).is_equal(250.0)


func test_patience_holds_while_the_uncles_are_still_walking_in() -> void:
	var run := Run.new(RunConfig.new(TestContent.uncle_crowd(20), 2))

	# They arrive at least 212 px away and walk 40 px/s, so nobody is near
	# her after 4 s.
	_stand(run, 4 * Run.STEPS_PER_SECOND)

	var snapshot := run.snapshot()
	assert_float(snapshot.patience).is_equal(100.0)
	assert_int(_touching_count(snapshot)).is_equal(0)


func test_one_touching_uncle_drains_ten_patience_per_second() -> void:
	var run := Run.new(RunConfig.new(TestContent.uncle_crowd(1), 3))
	_stand_until_first_touch(run)
	var before: float = run.snapshot().patience

	_stand(run, 3 * Run.STEPS_PER_SECOND)

	# Design §7: a Dowry Uncle drains 10 Patience per second.
	var snapshot := run.snapshot()
	assert_float(before - snapshot.patience).is_equal_approx(30.0, 0.0001)
	# He's pressed against her: her 6 px body circle against his 7 px one.
	assert_bool(snapshot.admirers[0].touching).is_true()
	assert_float(snapshot.admirers[0].position.length()).is_equal_approx(13.0, 0.01)


func test_several_touching_uncles_each_drain_ten_patience_per_second() -> void:
	# Plenty of Patience, so she lasts while all three walk in and press on.
	var content := TestContent.crowd(TestContent.real_uncle(), 3, TestContent.shireen_with_patience(1000.0))
	var run := Run.new(RunConfig.new(content, 5))

	var most_touching: int = _assert_each_touching_admirer_drains(run, 20, 10.0)

	assert_int(most_touching).is_equal(3)
	# With all three on her, a second costs 30 Patience.
	assert_int(_touching_count(run.snapshot())).is_equal(3)
	var before: float = run.snapshot().patience
	_stand(run, Run.STEPS_PER_SECOND)
	assert_float(before - run.snapshot().patience).is_equal_approx(30.0, 0.0001)


## In a crush only the ring pressed against her drains; the Uncles queueing
## behind them don't.
func test_in_a_crowd_only_the_uncles_touching_her_drain() -> void:
	var content := TestContent.crowd(TestContent.real_uncle(), 40, TestContent.shireen_with_patience(1000.0))
	var run := Run.new(RunConfig.new(content, 8))

	var most_touching: int = _assert_each_touching_admirer_drains(run, 15, 10.0)

	# About six 7 px Uncles fit around her 6 px body.
	assert_int(most_touching).is_between(4, 7)
	assert_float(run.snapshot().patience).is_greater(0.0)


func test_each_admirer_type_drains_at_its_own_rate() -> void:
	var suitor := TestContent.made_up_admirer(&"test_suitor", 25.0)
	var run := Run.new(RunConfig.new(TestContent.crowd(suitor, 1), 3))
	_stand_until_first_touch(run)
	var before: float = run.snapshot().patience

	_stand(run, 2 * Run.STEPS_PER_SECOND)

	assert_float(before - run.snapshot().patience).is_equal_approx(50.0, 0.0001)


func test_the_run_ends_in_defeat_when_patience_reaches_zero() -> void:
	var run := Run.new(RunConfig.new(TestContent.uncle_crowd(1), 3))
	assert_int(run.snapshot().phase).is_equal(Run.Phase.PLAYING)
	assert_int(run.snapshot().outcome).is_equal(Run.Outcome.NONE)
	_stand_until_first_touch(run)
	var first_touch_tick: int = run.snapshot().tick

	var events := _stand_until_the_end(run)

	var snapshot := run.snapshot()
	assert_float(snapshot.patience).is_equal(0.0)
	assert_int(snapshot.phase).is_equal(Run.Phase.ENDED)
	assert_int(snapshot.outcome).is_equal(Run.Outcome.DEFEAT)
	# One Uncle at 10 per second takes 10 s (600 steps, the first touch being
	# the first of them) to wear down 100 Patience. A step either way allows
	# for float rounding in six hundred subtractions.
	assert_int(snapshot.tick - first_touch_tick).is_between(598, 600)
	# The only event in all that time is the ending, from the very last step.
	assert_int(events.size()).is_equal(1)
	var ended := events[0] as RunEndedEvent
	assert_object(ended).is_not_null()
	assert_int(ended.outcome).is_equal(Run.Outcome.DEFEAT)


func test_the_run_ended_event_names_the_admirer_type_that_touched_her_last() -> void:
	var uncles := Run.new(RunConfig.new(TestContent.uncle_crowd(5), 6))
	var suitors := Run.new(RunConfig.new(TestContent.crowd(TestContent.made_up_admirer(&"test_suitor", 25.0), 5), 6))
	# Nobody has touched her yet.
	assert_str(uncles.snapshot().last_touching_type).is_equal("")

	var uncles_ending := _ending_of(uncles)
	var suitors_ending := _ending_of(suitors)

	assert_str(uncles_ending.last_touching_type).is_equal("dowry_uncle")
	assert_str(uncles.snapshot().last_touching_type).is_equal("dowry_uncle")
	assert_str(suitors_ending.last_touching_type).is_equal("test_suitor")
	assert_str(suitors.snapshot().last_touching_type).is_equal("test_suitor")


func test_nothing_changes_after_the_run_has_ended() -> void:
	var run := Run.new(RunConfig.new(TestContent.uncle_crowd(5), 6))
	_stand_until_the_end(run)
	var at_the_end: Dictionary = run.snapshot().to_dict()

	# Two more seconds of trying to walk away, with Uncles still on her.
	var events: Array[RunEvent] = []
	for i: int in 2 * Run.STEPS_PER_SECOND:
		events.append_array(run.step(Run.TIMESTEP, Vector2.RIGHT))

	# No more drain (Patience stays at 0 rather than going below it), no more
	# time, no walking, no new admirers, and the run doesn't end twice.
	assert_float(run.snapshot().patience).is_equal(0.0)
	assert_dict(run.snapshot().to_dict()).is_equal(at_the_end)
	assert_array(events).is_empty()


## A defeat replays exactly from its seed: the same tick, the same ending.
func test_the_same_seed_ends_the_run_on_the_same_step() -> void:
	var first := Run.new(RunConfig.new(TestContent.real(), 77))
	var second := Run.new(RunConfig.new(TestContent.real(), 77))

	var first_ending := _ending_of(first)
	var second_ending := _ending_of(second)

	assert_int(second.snapshot().tick).is_equal(first.snapshot().tick)
	assert_dict(second_ending.to_dict()).is_equal(first_ending.to_dict())
	assert_dict(second.snapshot().to_dict()).is_equal(first.snapshot().to_dict())


## The F12 state dump is built from the snapshot's plain-data form (RunView).
func test_the_state_dump_reports_patience_and_how_the_run_stands() -> void:
	var run := Run.new(RunConfig.new(TestContent.uncle_crowd(1), 3))
	_stand_until_first_touch(run)
	_stand(run, 2 * Run.STEPS_PER_SECOND)

	var playing: Dictionary = run.snapshot().to_dict()
	assert_float(playing["patience"]).is_equal(run.snapshot().patience)
	assert_float(playing["patience"]).is_between(75.0, 85.0)
	assert_float(playing["max_patience"]).is_equal(100.0)
	assert_str(playing["phase"]).is_equal("playing")
	assert_str(playing["outcome"]).is_equal("none")

	_stand_until_the_end(run)

	var ended: Dictionary = run.snapshot().to_dict()
	assert_float(ended["patience"]).is_equal(0.0)
	assert_str(ended["phase"]).is_equal("ended")
	assert_str(ended["outcome"]).is_equal("defeat")
	assert_str(ended["last_touching_type"]).is_equal("dowry_uncle")
	# This run has no weapon, so nobody was dazzled and no cash dropped.
	assert_int(ended["admirers_dazzled"]).is_equal(0)
	assert_int(ended["cash_collected"]).is_equal(0)
