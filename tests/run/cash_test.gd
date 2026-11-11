extends GdUnitTestSuite
## Cash and the level bar, checked through the Run seam (ADR-0001): dazzle
## admirers with the Zills, look at the pickups in the snapshot, walk over to
## them, and watch the cash and level counters and the leveled-up events.

## The small screen most Zills tests use: admirers arrive at most 190 px away.
const SMALL_SCREEN: Vector2 = Vector2(200, 200)


## A Zills run on [param play_area].
func _zills_run(content: ContentRegistry, rng_seed: int, play_area: Vector2 = RunConfig.DEFAULT_PLAY_AREA) -> Run:
	return Run.new(RunConfig.new(content, rng_seed, play_area, &"zills"))


## Stands still for [param ticks] steps, taking a card at every level-up so
## the run goes on (see [method _take_a_card_if_offered]).
func _stand(run: Run, ticks: int) -> Array[RunEvent]:
	var events: Array[RunEvent] = []
	for i: int in ticks:
		_take_a_card_if_offered(run)
		events.append_array(run.step(Run.TIMESTEP, Vector2.ZERO))
	return events


## These tests are about cash, not cards (tests/run/level_up_test.gd): when
## the run pauses on a level-up, take the first card that isn't Count, so
## the one-hit Zills keep dazzling one Uncle a throw and the cash arrives
## at a steady pace.
func _take_a_card_if_offered(run: Run) -> void:
	var snapshot := run.snapshot()
	if snapshot.phase != Run.Phase.LEVEL_UP:
		return
	for i: int in snapshot.cards.size():
		if snapshot.cards[i].id != &"count":
			run.choose_card(i)
			return
	run.choose_card(0)


## The admirer with [param id] in [param snapshot], or null once he's gone.
func _admirer(snapshot: RunSnapshot, id: int) -> AdmirerSnapshot:
	for admirer: AdmirerSnapshot in snapshot.admirers:
		if admirer.id == id:
			return admirer
	return null


## The pickup with [param id] in [param snapshot], or null once it's gone.
## Ids count up from 1 in the order dropped.
func _pickup(snapshot: RunSnapshot, id: int) -> PickupSnapshot:
	for pickup: PickupSnapshot in snapshot.pickups:
		if pickup.id == id:
			return pickup
	return null


## Steps [param run] standing still until the first admirer is dazzled, and
## returns him as he was in that very step.
func _stand_until_someone_is_dazzled(run: Run) -> AdmirerSnapshot:
	for i: int in 15 * Run.STEPS_PER_SECOND:
		run.step(Run.TIMESTEP, Vector2.ZERO)
		for admirer: AdmirerSnapshot in run.snapshot().admirers:
			if admirer.state != Admirer.State.CHASING:
				return admirer
	fail("nobody was dazzled within 15 s")
	return null


# --- Drops ------------------------------------------------------------------

func test_a_dazzled_uncle_drops_cash_worth_his_value_where_he_stood() -> void:
	# The real Dowry Uncle is worth 2 cash (design §7). On the full-size
	# screen the zill meets him well over 100 px out, far outside her 24 px
	# pickup radius, so the cash lies where it fell.
	var content := TestContent.weapon_against(TestContent.one_hit_zills(), TestContent.harmless_uncle(), 1)
	var run := _zills_run(content, 5)

	var uncle: AdmirerSnapshot = _stand_until_someone_is_dazzled(run)

	var snapshot := run.snapshot()
	assert_int(snapshot.pickups.size()).is_equal(1)
	var cash: PickupSnapshot = snapshot.pickups[0]
	assert_int(cash.id).is_equal(1)
	assert_int(cash.kind).is_equal(Pickup.Kind.CASH)
	assert_int(cash.value).is_equal(2)
	assert_vector(cash.position).is_equal(uncle.position)
	assert_int(cash.state).is_equal(Pickup.State.ON_GROUND)
	assert_float(cash.position.length()).is_greater(24.0)
	assert_int(snapshot.cash_collected).is_equal(0)


func test_bigger_admirers_drop_bigger_bills() -> void:
	# Design §7: each type has its own cash value, like the Falconer's 4.
	var content := TestContent.weapon_against(TestContent.one_hit_zills(), TestContent.uncle_worth(4), 1)
	var run := _zills_run(content, 5)

	_stand_until_someone_is_dazzled(run)

	assert_int(run.snapshot().pickups[0].value).is_equal(4)


func test_cash_outside_the_pickup_radius_lies_where_it_fell() -> void:
	var content := TestContent.weapon_against(TestContent.one_hit_zills(), TestContent.harmless_uncle(), 1)
	var run := _zills_run(content, 5)
	_stand_until_someone_is_dazzled(run)
	var dropped: Vector2 = _pickup(run.snapshot(), 1).position

	_stand(run, 3 * Run.STEPS_PER_SECOND)

	var cash: PickupSnapshot = _pickup(run.snapshot(), 1)
	assert_object(cash).is_not_null()
	assert_vector(cash.position).is_equal(dropped)
	assert_int(cash.state).is_equal(Pickup.State.ON_GROUND)
	assert_int(run.snapshot().cash_collected).is_equal(0)


# --- The pickup radius and the flight to her --------------------------------

## A run where one Uncle has just been dazzled far from Shireen, whose pickup
## radius is [param pickup_radius].
func _run_with_cash_on_the_ground(pickup_radius: float) -> Run:
	var shireen := TestContent.shireen_with_pickup_radius(pickup_radius)
	var content := TestContent.weapon_against(TestContent.one_hit_zills(), TestContent.harmless_uncle(), 1, shireen)
	var run := _zills_run(content, 5)
	_stand_until_someone_is_dazzled(run)
	assert_int(_pickup(run.snapshot(), 1).state).is_equal(Pickup.State.ON_GROUND)
	return run


## Walks [param run]'s Shireen straight at the first cash dropped until it
## starts flying, and returns how far from her it was just before that step.
## She walks 1.5 px a step, so this brackets the pickup radius.
func _walk_until_the_cash_flies(run: Run) -> float:
	var cash: PickupSnapshot = _pickup(run.snapshot(), 1)
	var dropped: Vector2 = cash.position
	var toward: Vector2 = (dropped - run.snapshot().shireen_position).normalized()
	var distance_before: float = dropped.distance_to(run.snapshot().shireen_position)
	for i: int in 10 * Run.STEPS_PER_SECOND:
		run.step(Run.TIMESTEP, toward)
		var snapshot := run.snapshot()
		cash = _pickup(snapshot, 1)
		assert_object(cash).is_not_null()
		if cash.state == Pickup.State.FLYING:
			return distance_before
		# On the ground it never moves.
		assert_vector(cash.position).is_equal(dropped)
		distance_before = dropped.distance_to(snapshot.shireen_position)
	fail("the cash never started flying")
	return -1.0


func test_cash_starts_flying_once_shireen_comes_within_her_24_pixel_pickup_radius() -> void:
	# Design §4: a 24 px pickup radius. Just before the step it started
	# flying it was still outside the radius, and one 1.5 px step later
	# inside it.
	var run := _run_with_cash_on_the_ground(24.0)

	assert_float(_walk_until_the_cash_flies(run)).is_between(24.0, 25.5)


func test_the_pickup_radius_comes_from_shireens_data() -> void:
	var run := _run_with_cash_on_the_ground(60.0)

	assert_float(_walk_until_the_cash_flies(run)).is_between(60.0, 61.5)


func test_flying_cash_closes_in_on_shireen_every_step_until_she_collects_it() -> void:
	var run := _run_with_cash_on_the_ground(24.0)
	_walk_until_the_cash_flies(run)
	var distance: float = _pickup(run.snapshot(), 1).position.distance_to(run.snapshot().shireen_position)
	var steps_in_flight: int = 1

	for i: int in Run.STEPS_PER_SECOND:
		run.step(Run.TIMESTEP, Vector2.ZERO)
		var snapshot := run.snapshot()
		var cash: PickupSnapshot = _pickup(snapshot, 1)
		if cash == null:
			break
		steps_in_flight += 1
		assert_int(cash.state).is_equal(Pickup.State.FLYING)
		var now: float = cash.position.distance_to(snapshot.shireen_position)
		assert_float(now).is_less(distance)
		distance = now

	# At the real 320 px/s it covers 24 px in a handful of steps.
	assert_object(_pickup(run.snapshot(), 1)).is_null()
	assert_int(steps_in_flight).is_between(2, 6)
	assert_int(run.snapshot().cash_collected).is_equal(2)


func test_flying_cash_catches_shireen_even_as_she_walks_away() -> void:
	var run := _run_with_cash_on_the_ground(24.0)
	_walk_until_the_cash_flies(run)
	var away: Vector2 = (run.snapshot().shireen_position - _pickup(run.snapshot(), 1).position).normalized()

	# She walks 90 px/s; cash flies 320 px/s.
	for i: int in Run.STEPS_PER_SECOND:
		run.step(Run.TIMESTEP, away)

	assert_object(_pickup(run.snapshot(), 1)).is_null()
	assert_int(run.snapshot().cash_collected).is_equal(2)


# --- The level bar ----------------------------------------------------------

## A run where the first throw comes at 1.2 s and then every 0.2 s, one
## dazzle a throw, against 20 Uncles worth [param cash] each. Shireen's pickup
## radius covers the whole small screen, so every bill flies to her at once.
func _run_collecting_fast(cash: int, leveling: LevelingData = null) -> Run:
	var shireen := TestContent.shireen_with_pickup_radius(200.0)
	var content := ContentRegistry.from_data(shireen, [TestContent.uncle_worth(cash)], TestContent.steady_spawns(&"dowry_uncle", 100.0, 20), [TestContent.one_hit_zills(0.2)], leveling)
	return _zills_run(content, 9, SMALL_SCREEN)


## The levels of the leveled-up events in [param events], in order.
func _levels_reached(events: Array[RunEvent]) -> Array[int]:
	var levels: Array[int] = []
	for event: RunEvent in events:
		if event is LeveledUpEvent:
			levels.append((event as LeveledUpEvent).level)
	return levels


func test_a_new_run_starts_at_level_1_with_an_empty_level_bar() -> void:
	var snapshot := _zills_run(TestContent.real(), 1).snapshot()

	assert_int(snapshot.level).is_equal(1)
	assert_int(snapshot.level_cash).is_equal(0)
	# Design §5: the first level-up takes 5 cash.
	assert_int(snapshot.level_cash_needed).is_equal(5)
	assert_int(snapshot.cash_collected).is_equal(0)
	assert_array(snapshot.pickups).is_empty()


func test_cash_fills_the_level_bar_along_the_design_curve() -> void:
	# Design §5: level n -> n+1 takes 5 + 3·(n−1) cash, so the level-ups
	# come at 5, 13, 24 and 38 cash in all, and the bar then needs 5, 8, 11,
	# 14 and 17.
	var level_up_at: Array[int] = [5, 13, 24, 38]
	var bar_needs: Array[int] = [5, 8, 11, 14, 17]
	var run := _run_collecting_fast(1)
	var levels_reached: Array[int] = []
	var previous_level: int = 1

	for i: int in 30 * Run.STEPS_PER_SECOND:
		_take_a_card_if_offered(run)
		var events := run.step(Run.TIMESTEP, Vector2.ZERO)
		var snapshot := run.snapshot()
		var expected_level: int = 1
		var spent: int = 0
		for threshold: int in level_up_at:
			if snapshot.cash_collected >= threshold:
				expected_level += 1
				spent = threshold
		assert_int(snapshot.level).is_equal(expected_level)
		assert_int(snapshot.level_cash).is_equal(snapshot.cash_collected - spent)
		assert_int(snapshot.level_cash_needed).is_equal(bar_needs[expected_level - 1])
		# A level-up is announced in the very step it happens, and only then.
		var announced: Array[int] = _levels_reached(events)
		assert_array(announced).is_equal(range(previous_level + 1, snapshot.level + 1))
		levels_reached.append_array(announced)
		previous_level = snapshot.level
		if snapshot.level == 5:
			break

	assert_array(levels_reached).is_equal([2, 3, 4, 5])
	assert_int(run.snapshot().cash_collected).is_between(38, 40)


func test_a_big_bill_is_worth_several_levels_at_once() -> void:
	# 100 cash from one bill: 5 + 8 + 11 + 14 + 17 + 20 + 23 = 98 pays for
	# seven level-ups, with 2 left toward the 26 for the eighth.
	var run := _run_collecting_fast(100)
	var collecting_step: Array[RunEvent] = []

	for i: int in 10 * Run.STEPS_PER_SECOND:
		var events := run.step(Run.TIMESTEP, Vector2.ZERO)
		if run.snapshot().cash_collected > 0:
			collecting_step = events
			break

	assert_array(_levels_reached(collecting_step)).is_equal([2, 3, 4, 5, 6, 7, 8])
	var snapshot := run.snapshot()
	assert_int(snapshot.cash_collected).is_equal(100)
	assert_int(snapshot.level).is_equal(8)
	assert_int(snapshot.level_cash).is_equal(2)
	assert_int(snapshot.level_cash_needed).is_equal(26)


func test_the_leveling_curve_comes_from_data() -> void:
	# A flat 10 cash a level, paid in bills of 10: every bill is a level.
	var run := _run_collecting_fast(10, TestContent.leveling(10, 0))

	for i: int in 10 * Run.STEPS_PER_SECOND:
		_take_a_card_if_offered(run)
		run.step(Run.TIMESTEP, Vector2.ZERO)
		if run.snapshot().cash_collected >= 30:
			break

	var snapshot := run.snapshot()
	assert_int(snapshot.cash_collected).is_equal(30)
	assert_int(snapshot.level).is_equal(4)
	assert_int(snapshot.level_cash).is_equal(0)
	assert_int(snapshot.level_cash_needed).is_equal(10)


# --- Determinism and the state dump -----------------------------------------

## Cash drops, flights and collections replay exactly from the seed.
func test_the_same_seed_drops_and_collects_the_same_cash() -> void:
	var first := _run_collecting_fast(2)
	var second := _run_collecting_fast(2)
	var saw_a_pickup: bool = false

	for i: int in 5 * Run.STEPS_PER_SECOND:
		_take_a_card_if_offered(first)
		_take_a_card_if_offered(second)
		first.step(Run.TIMESTEP, Vector2.ZERO)
		second.step(Run.TIMESTEP, Vector2.ZERO)
		var snapshot: Dictionary = first.snapshot().to_dict()
		assert_dict(second.snapshot().to_dict()).is_equal(snapshot)
		if not (snapshot["pickups"] as Array).is_empty():
			saw_a_pickup = true

	assert_bool(saw_a_pickup).is_true()
	assert_int(first.snapshot().cash_collected).is_greater(10)


## The F12 state dump is built from the snapshot's plain-data form (RunView).
func test_the_state_dump_reports_the_cash_the_level_and_the_pickups() -> void:
	var run := _zills_run(TestContent.weapon_against(TestContent.one_hit_zills(), TestContent.harmless_uncle(), 1), 5)
	_stand_until_someone_is_dazzled(run)

	var state: Dictionary = run.snapshot().to_dict()

	assert_int(state["cash_collected"]).is_equal(0)
	assert_int(state["level"]).is_equal(1)
	assert_int(state["level_cash"]).is_equal(0)
	assert_int(state["level_cash_needed"]).is_equal(5)
	var pickups: Array = state["pickups"]
	assert_int(pickups.size()).is_equal(1)
	assert_str(pickups[0]["kind"]).is_equal("cash")
	assert_str(pickups[0]["state"]).is_equal("on_ground")
	assert_int(pickups[0]["value"]).is_equal(2)


# --- Performance ------------------------------------------------------------

## The step budget from tests/run/dowry_uncle_test.gd, where it is calibrated:
## 20% of a 60 Hz frame for a step plus the snapshot after it, the pair the
## view pays for every frame.
const STEP_BUDGET_USEC: float = 3300.0


## Hundreds of bills on the sand on top of the full crowd of 300: every step
## looks at each bill and the snapshot copies them all. Shireen's pickup
## radius is the smallest the content allows, so nothing is ever collected
## and the bills pile up around her. Five one-hit zills every 0.1 s dazzle
## about 50 Uncles a second, each replaced at once.
##
## Measured on the user's machine (2026-11-10): about 2,500 µs with 617
## bills, against 1,200 for the crowd of 300 alone. Most of the difference
## is the snapshot copying every bill, which the view reads every frame.
func test_hundreds_of_bills_on_the_sand_step_within_the_time_budget() -> void:
	var shireen := TestContent.shireen_with_pickup_radius(1.0)
	var zills := TestContent.zills_with({&"damage": 30.0, &"cooldown": 0.1, &"count": 5.0})
	var content := ContentRegistry.from_data(shireen, [TestContent.harmless_uncle()], TestContent.steady_spawns(&"dowry_uncle", 100.0, 300), [zills])
	var run := _zills_run(content, 17)
	_stand(run, 15 * Run.STEPS_PER_SECOND)
	var snapshot := run.snapshot()
	assert_int(snapshot.pickups.size()).is_greater(500)
	assert_int(snapshot.admirer_count).is_equal(300)

	var started: int = Time.get_ticks_usec()
	for i: int in 300:
		run.step(Run.TIMESTEP, Vector2.ZERO)
		run.snapshot()
	var average_usec: float = float(Time.get_ticks_usec() - started) / 300

	print("%d bills and %d admirers: %.0f µs per step and snapshot (budget %.0f)" % [snapshot.pickups.size(), snapshot.admirer_count, average_usec, STEP_BUDGET_USEC])
	assert_float(average_usec).is_less(STEP_BUDGET_USEC)
