extends GdUnitTestSuite
## Karkadeh tea, the rare Patience pickup, checked through the Run seam
## (ADR-0001): dazzle Uncles with a tea drop chance set in the content, look
## at the pickups, walk over the cup and watch her Patience.

const SMALL_SCREEN: Vector2 = Vector2(200, 200)


## A Zills run against [param count] admirers of one type, with
## [param tea_drop_chance] (0 to 1) of tea per dazzle.
func _tea_run(tea_drop_chance: float, admirer: AdmirerData, count: int, weapon: WeaponData, rng_seed: int, play_area: Vector2 = RunConfig.DEFAULT_PLAY_AREA, shireen: ShireenData = TestContent.real().shireen) -> Run:
	var content := ContentRegistry.from_data(shireen, [admirer], TestContent.steady_spawns(admirer.id, 100.0, count), [weapon], null, TestContent.pickups(tea_drop_chance))
	return Run.new(RunConfig.new(content, rng_seed, play_area, &"zills"))


## Stands still for [param ticks] steps. These tests are about tea, not
## cards (tests/run/level_up_test.gd): at every level-up the first card is
## taken, so the run goes on.
func _stand(run: Run, ticks: int) -> void:
	for i: int in ticks:
		if run.snapshot().phase == Run.Phase.LEVEL_UP:
			run.choose_card(0)
		run.step(Run.TIMESTEP, Vector2.ZERO)


## Steps [param run] standing still until someone is dazzled.
func _stand_until_someone_is_dazzled(run: Run) -> void:
	for i: int in 15 * Run.STEPS_PER_SECOND:
		run.step(Run.TIMESTEP, Vector2.ZERO)
		if run.snapshot().admirers_dazzled > 0:
			return
	fail("nobody was dazzled within 15 s")


## The pickups of [param kind] in [param snapshot].
func _of_kind(snapshot: RunSnapshot, kind: Pickup.Kind) -> Array[PickupSnapshot]:
	var found: Array[PickupSnapshot] = []
	for pickup: PickupSnapshot in snapshot.pickups:
		if pickup.kind == kind:
			found.append(pickup)
	return found


## The pickup with [param id] in [param snapshot], or null once it's gone.
func _pickup(snapshot: RunSnapshot, id: int) -> PickupSnapshot:
	for pickup: PickupSnapshot in snapshot.pickups:
		if pickup.id == id:
			return pickup
	return null


## Walks [param run]'s Shireen straight at the first cup of tea until she has
## picked it up. Returns [distance to the cup before the step she picked it
## up, her Patience before that step]. (The admirer who replaces the dazzled
## one may drop a second cup on the way; this follows the first by its id.)
func _walk_over_the_tea(run: Run) -> Array[float]:
	var cup: PickupSnapshot = _of_kind(run.snapshot(), Pickup.Kind.TEA)[0]
	var toward: Vector2 = (cup.position - run.snapshot().shireen_position).normalized()
	var distance_before: float = cup.position.distance_to(run.snapshot().shireen_position)
	var patience_before: float = run.snapshot().patience
	for i: int in 10 * Run.STEPS_PER_SECOND:
		run.step(Run.TIMESTEP, toward)
		var snapshot := run.snapshot()
		var still_there: PickupSnapshot = _pickup(snapshot, cup.id)
		if still_there == null:
			return [distance_before, patience_before]
		# Tea never flies: it waits where it dropped.
		assert_vector(still_there.position).is_equal(cup.position)
		assert_int(still_there.state).is_equal(Pickup.State.ON_GROUND)
		distance_before = cup.position.distance_to(snapshot.shireen_position)
		patience_before = snapshot.patience
	fail("she never picked up the tea")
	return [-1.0, -1.0]


func test_a_sure_tea_chance_drops_a_cup_with_every_dazzle() -> void:
	var run := _tea_run(1.0, TestContent.harmless_uncle(), 1, TestContent.one_hit_zills(), 5)

	_stand_until_someone_is_dazzled(run)

	var snapshot := run.snapshot()
	var cash: Array[PickupSnapshot] = _of_kind(snapshot, Pickup.Kind.CASH)
	var tea: Array[PickupSnapshot] = _of_kind(snapshot, Pickup.Kind.TEA)
	assert_int(snapshot.pickups.size()).is_equal(2)
	assert_int(cash.size()).is_equal(1)
	assert_int(tea.size()).is_equal(1)
	# The cup drops at his feet, next to his cash.
	assert_vector(tea[0].position).is_equal(cash[0].position)
	assert_int(tea[0].value).is_equal(0)
	assert_int(tea[0].state).is_equal(Pickup.State.ON_GROUND)


func test_no_tea_chance_drops_no_tea() -> void:
	var run := _tea_run(0.0, TestContent.harmless_uncle(), 1, TestContent.one_hit_zills(), 5)

	_stand_until_someone_is_dazzled(run)

	assert_int(run.snapshot().pickups.size()).is_equal(1)
	assert_array(_of_kind(run.snapshot(), Pickup.Kind.TEA)).is_empty()


func test_tea_waits_on_the_ground_until_shireen_walks_over_it() -> void:
	# Unlike cash, it doesn't fly to her from 24 px: she has to touch it, so
	# she can save a cup for later.
	var run := _tea_run(1.0, TestContent.harmless_uncle(), 1, TestContent.one_hit_zills(), 5)
	_stand_until_someone_is_dazzled(run)

	var distance_before: float = _walk_over_the_tea(run)[0]

	# She reaches a cup when her body circle touches it: in the real content
	# her 6 px body against a 5 px cup. Just before the step she picked it up
	# it was still out of reach, and one 1.5 px step later within it.
	var content := TestContent.real()
	var reach: float = content.shireen.body_radius + content.pickups.tea_radius
	assert_float(reach).is_equal(11.0)
	assert_float(distance_before).is_between(reach, reach + 1.5)


## A run where the one dazzling throw comes at 10 s, when the one admirer of
## [param admirer]'s type has been pressed against Shireen for seconds,
## draining her. The tea he drops lands at his feet, 13 px from her.
func _run_with_a_late_tea_drop(admirer: AdmirerData) -> Run:
	var run := _tea_run(1.0, admirer, 1, TestContent.one_hit_zills(10.0), 5, SMALL_SCREEN)
	_stand_until_someone_is_dazzled(run)
	assert_int(_of_kind(run.snapshot(), Pickup.Kind.TEA).size()).is_equal(1)
	return run


func test_tea_restores_30_patience() -> void:
	# A real Uncle drains 10 a second for the ~6 s he stands on her: she's
	# at about 35 when the tea drops.
	var run := _run_with_a_late_tea_drop(TestContent.real_uncle())
	assert_float(run.snapshot().patience).is_between(25.0, 45.0)

	var patience_before: float = _walk_over_the_tea(run)[1]

	# Design §4: tea restores 30 Patience. Nobody drains her in that step:
	# the Uncle who dropped it is dazzled.
	assert_float(run.snapshot().patience - patience_before).is_equal_approx(30.0, 0.0001)
	assert_float(run.snapshot().patience).is_less(100.0)


func test_tea_never_restores_patience_past_the_maximum() -> void:
	# A gentle suitor drains 1 a second: she's at about 93 when the tea drops.
	var run := _run_with_a_late_tea_drop(TestContent.made_up_admirer(&"test_suitor", 1.0))
	assert_float(run.snapshot().patience).is_between(85.0, 99.0)

	_walk_over_the_tea(run)

	assert_float(run.snapshot().patience).is_equal(100.0)
	assert_float(run.snapshot().max_patience).is_equal(100.0)


func test_tea_rolls_come_from_the_seed() -> void:
	# A coin flip per dazzle, about 55 dazzles: the same seed flips the same
	# coins, and the coins really are coins (not all heads, not all tails).
	# Her pickup radius covers the screen so the cash is out of the way; the
	# cups land 13 px from her, just out of reach, and pile up on the sand.
	var shireen := TestContent.shireen_with_pickup_radius(200.0)
	var first := _tea_run(0.5, TestContent.harmless_uncle(), 20, TestContent.one_hit_zills(0.2), 9, SMALL_SCREEN, shireen)
	var second := _tea_run(0.5, TestContent.harmless_uncle(), 20, TestContent.one_hit_zills(0.2), 9, SMALL_SCREEN, shireen)

	_stand(first, 12 * Run.STEPS_PER_SECOND)
	_stand(second, 12 * Run.STEPS_PER_SECOND)

	var dazzled: int = first.snapshot().admirers_dazzled
	var cups: int = _of_kind(first.snapshot(), Pickup.Kind.TEA).size()
	assert_int(dazzled).is_greater(40)
	assert_int(cups).is_between(int(dazzled * 0.2), int(dazzled * 0.8))
	assert_dict(second.snapshot().to_dict()).is_equal(first.snapshot().to_dict())
