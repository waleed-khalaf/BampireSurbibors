extends GdUnitTestSuite
## Shireen's Zills, checked through the Run seam (ADR-0001): build a Run with
## the Zills as its weapon, step it, look at the snapshot.

## A small screen, so admirers arrive at most 190 px away: well inside the
## real Zills' range from their first step.
const SMALL_SCREEN: Vector2 = Vector2(200, 200)


## A Run with the Zills as its weapon. [param buff_ranks] starts it with
## some buff tracks already ranked up, e.g. {&"damage": 5}.
func _zills_run(content: ContentRegistry, rng_seed: int, play_area: Vector2 = SMALL_SCREEN, buff_ranks: Dictionary[StringName, int] = {}) -> Run:
	var config := RunConfig.new(content, rng_seed, play_area, &"zills")
	config.starting_buff_ranks = buff_ranks
	return Run.new(config)


func _stand(run: Run, ticks: int) -> void:
	for i: int in ticks:
		run.step(Run.TIMESTEP, Vector2.ZERO)


## The admirer with [param id] in [param snapshot], or null once he's gone.
## Ids count up from 1 in spawn order.
func _admirer(snapshot: RunSnapshot, id: int) -> AdmirerSnapshot:
	for admirer: AdmirerSnapshot in snapshot.admirers:
		if admirer.id == id:
			return admirer
	return null


## [param snapshot]'s admirers, the one nearest to Shireen first. Only for
## runs where she has stood still at (0, 0).
func _nearest_first(snapshot: RunSnapshot) -> Array[AdmirerSnapshot]:
	var admirers: Array[AdmirerSnapshot] = snapshot.admirers.duplicate()
	admirers.sort_custom(func(a: AdmirerSnapshot, b: AdmirerSnapshot) -> bool: return a.position.length() < b.position.length())
	return admirers


## Stands still for [param steps] steps and returns the tick of every throw.
func _throw_ticks(run: Run, steps: int) -> Array[int]:
	var ticks: Array[int] = []
	var thrown: int = run.snapshot().weapon.attacks
	for i: int in steps:
		run.step(Run.TIMESTEP, Vector2.ZERO)
		var snapshot := run.snapshot()
		if snapshot.weapon.attacks > thrown:
			thrown = snapshot.weapon.attacks
			ticks.append(snapshot.tick)
	return ticks


## Stands still for [param steps] steps and returns the HP of the admirer
## with [param id]: what he had at first, then each new value as it changed.
func _hp_seen(run: Run, id: int, steps: int) -> Array[float]:
	var seen: Array[float] = []
	for i: int in steps:
		run.step(Run.TIMESTEP, Vector2.ZERO)
		var admirer: AdmirerSnapshot = _admirer(run.snapshot(), id)
		if admirer != null and (seen.is_empty() or admirer.hp != seen.back()):
			seen.append(admirer.hp)
	return seen


func test_the_real_zills_throw_one_zill_every_1_2_seconds() -> void:
	var content := TestContent.weapon_against(TestContent.real_zills(), TestContent.tough_uncle(), 1)
	var run := _zills_run(content, 5)
	var throw_ticks: Array[int] = []
	var zill_ids: Dictionary[int, bool] = {}

	for i: int in 6 * Run.STEPS_PER_SECOND:
		run.step(Run.TIMESTEP, Vector2.ZERO)
		var snapshot := run.snapshot()
		if snapshot.weapon.attacks > throw_ticks.size():
			throw_ticks.append(snapshot.tick)
		for zill: ProjectileSnapshot in snapshot.projectiles:
			zill_ids[zill.id] = true

	# 1.2 s is 72 steps: five throws in 6 seconds, one zill each.
	assert_array(throw_ticks).is_equal([72, 144, 216, 288, 360])
	assert_int(zill_ids.size()).is_equal(5)


func test_zills_hold_fire_while_no_admirer_is_around() -> void:
	var content := ContentRegistry.from_data(TestContent.real().shireen, [], null, [TestContent.real_zills()])
	var run := _zills_run(content, 5)

	_stand(run, 10 * Run.STEPS_PER_SECOND)

	assert_int(run.snapshot().weapon.attacks).is_equal(0)
	assert_array(run.snapshot().projectiles).is_empty()


func test_after_waiting_for_an_admirer_the_next_throw_is_a_full_cooldown_later() -> void:
	# One Uncle, who arrives after 2 s: by then the Zills have been ready to
	# throw for most of a second.
	var spawns := TestContent.steady_spawns(&"dowry_uncle", 0.5, 1)
	var content := ContentRegistry.from_data(TestContent.real().shireen, [TestContent.tough_uncle()], spawns, [TestContent.real_zills()])
	var run := _zills_run(content, 5)

	var throw_ticks: Array[int] = _throw_ticks(run, 5 * Run.STEPS_PER_SECOND)

	# The first throw is late. The time spent waiting for it must not count
	# toward the next one: 1.2 s is 72 steps, as ever.
	assert_int(throw_ticks[0]).is_greater(72)
	assert_int(throw_ticks[1] - throw_ticks[0]).is_equal(72)
	assert_int(throw_ticks[2] - throw_ticks[1]).is_equal(72)


func test_a_zill_flies_at_the_nearest_admirer() -> void:
	# Five Uncles arrive from all around, each from a different distance.
	var content := TestContent.weapon_against(TestContent.real_zills(), TestContent.tough_uncle(), 5)
	var run := _zills_run(content, 8)

	# The first throw comes on step 72 (1.2 s).
	_stand(run, 72)

	var snapshot := run.snapshot()
	var by_distance: Array[AdmirerSnapshot] = _nearest_first(snapshot)
	assert_int(snapshot.projectiles.size()).is_equal(1)
	var zill: ProjectileSnapshot = snapshot.projectiles[0]
	# It starts in Shireen's hands (she stands at 0, 0), flying at the real
	# Zills' 220 px/s, straight at the nearest Uncle...
	assert_vector(zill.position).is_equal(Vector2.ZERO)
	assert_float(zill.velocity.length()).is_equal_approx(220.0, 0.001)
	assert_vector(zill.velocity.normalized()).is_equal_approx(by_distance[0].position.normalized(), Vector2(0.0001, 0.0001))
	# ...and the next nearest really is somewhere else, so this isn't luck.
	assert_float(zill.velocity.normalized().dot(by_distance[1].position.normalized())).is_less(0.9)


func test_three_zills_dazzle_a_dowry_uncle() -> void:
	# The real numbers: an Uncle has 30 HP and a zill does 10 damage.
	var content := TestContent.weapon_against(TestContent.real_zills(), TestContent.harmless_uncle(), 1)
	var run := _zills_run(content, 5)

	# The throws come at 1.2, 2.4 and 3.6 s. After two hits he is still
	# after her...
	assert_array(_hp_seen(run, 1, 3 * Run.STEPS_PER_SECOND)).is_equal([30.0, 20.0, 10.0])
	assert_int(_admirer(run.snapshot(), 1).state).is_equal(Admirer.State.CHASING)
	assert_int(run.snapshot().admirers_dazzled).is_equal(0)

	# ...and the third dazzles him.
	_stand(run, Run.STEPS_PER_SECOND)
	assert_float(_admirer(run.snapshot(), 1).hp).is_equal(0.0)
	assert_int(_admirer(run.snapshot(), 1).state).is_equal(Admirer.State.SWOONING)
	assert_int(run.snapshot().admirers_dazzled).is_equal(1)


# --- Pierce -----------------------------------------------------------------

## Throws exactly one zill with [param pierce] into 60 Uncles packed around
## Shireen, and returns how many Uncles it hit. The cooldown is stretched to
## 20 s so the crowd has packed in before the one throw, and the run stops
## after the zill has flown its whole range.
func _uncles_hit_by_one_zill(pierce: float) -> int:
	var zills := TestContent.zills_with({&"cooldown": 20.0, &"pierce": pierce})
	var run := _zills_run(TestContent.weapon_against(zills, TestContent.harmless_uncle(), 60), 31)

	_stand(run, 22 * Run.STEPS_PER_SECOND)

	var snapshot := run.snapshot()
	assert_int(snapshot.weapon.attacks).is_equal(1)
	assert_array(snapshot.projectiles).is_empty()
	var hit: int = 0
	for uncle: AdmirerSnapshot in snapshot.admirers:
		# Nobody is hit twice by the same zill: 30 HP, or 20 after one hit.
		assert_array([30.0, 20.0]).contains([uncle.hp])
		if uncle.hp == 20.0:
			hit += 1
	return hit


func test_a_zill_without_pierce_stops_at_the_first_admirer_it_hits() -> void:
	assert_int(_uncles_hit_by_one_zill(0.0)).is_equal(1)


func test_a_zill_with_pierce_2_flies_on_through_two_more_admirers() -> void:
	assert_int(_uncles_hit_by_one_zill(2.0)).is_equal(3)


# --- Count ------------------------------------------------------------------

func test_two_zills_per_throw_fly_at_the_two_nearest_admirers() -> void:
	var zills := TestContent.zills_with({&"count": 2.0})
	var run := _zills_run(TestContent.weapon_against(zills, TestContent.tough_uncle(), 5), 8)

	_stand(run, 72)

	var snapshot := run.snapshot()
	var by_distance: Array[AdmirerSnapshot] = _nearest_first(snapshot)
	assert_int(snapshot.projectiles.size()).is_equal(2)
	for i: int in 2:
		assert_vector(snapshot.projectiles[i].velocity.normalized()).is_equal_approx(by_distance[i].position.normalized(), Vector2(0.0001, 0.0001))


func test_spare_zills_all_fly_at_a_lone_admirer() -> void:
	# Three zills of 10 damage at once are enough for an Uncle's 30 HP.
	var zills := TestContent.zills_with({&"count": 3.0})
	var run := _zills_run(TestContent.weapon_against(zills, TestContent.harmless_uncle(), 1), 5)

	# One throw at 1.2 s; the next would come at 2.4 s.
	_stand(run, 2 * Run.STEPS_PER_SECOND)

	assert_int(run.snapshot().weapon.attacks).is_equal(1)
	assert_int(run.snapshot().admirers_dazzled).is_equal(1)


# --- Dazzled admirers -------------------------------------------------------

## A run where one zill dazzles an Uncle, and the first throw only comes at
## 10 s, when [param uncles] Uncles have long been pressed against Shireen.
## They are harmless unless [param uncle] and a [param shireen] with the
## Patience to last that long are given.
func _run_with_a_late_dazzling_throw(uncles: int, uncle: AdmirerData = TestContent.harmless_uncle(), shireen: ShireenData = TestContent.real().shireen) -> Run:
	var zills := TestContent.zills_with({&"cooldown": 10.0, &"damage": 30.0})
	return _zills_run(TestContent.weapon_against(zills, uncle, uncles, shireen), 5)


## The first dazzled admirer in [param snapshot], or null if there is none.
func _dazzled_admirer(snapshot: RunSnapshot) -> AdmirerSnapshot:
	for admirer: AdmirerSnapshot in snapshot.admirers:
		if admirer.state != Admirer.State.CHASING:
			return admirer
	return null


## Steps [param run] until someone has been dazzled, and returns him.
func _stand_until_someone_is_dazzled(run: Run) -> AdmirerSnapshot:
	for i: int in 15 * Run.STEPS_PER_SECOND:
		run.step(Run.TIMESTEP, Vector2.ZERO)
		var dazzled: AdmirerSnapshot = _dazzled_admirer(run.snapshot())
		if dazzled != null:
			return dazzled
	fail("nobody was dazzled within 15 s")
	return null


## Takes one step standing still and returns the Patience it cost Shireen.
func _patience_lost_in_one_step(run: Run) -> float:
	var before: float = run.snapshot().patience
	run.step(Run.TIMESTEP, Vector2.ZERO)
	return before - run.snapshot().patience


func test_a_dazzled_uncle_swoons_then_walks_off_screen_and_is_removed() -> void:
	var run := _run_with_a_late_dazzling_throw(1)
	var dazzled: AdmirerSnapshot = _stand_until_someone_is_dazzled(run)
	var swoon_steps: int = 1
	var last_seen: AdmirerSnapshot = dazzled
	var gone: bool = false

	for i: int in 10 * Run.STEPS_PER_SECOND:
		run.step(Run.TIMESTEP, Vector2.ZERO)
		var uncle: AdmirerSnapshot = _admirer(run.snapshot(), dazzled.id)
		if uncle == null:
			gone = true
			break
		if uncle.state == Admirer.State.SWOONING:
			# He swoons on the spot.
			swoon_steps += 1
			assert_vector(uncle.position).is_equal(dazzled.position)
		else:
			# Then he walks away from her, never back.
			assert_int(uncle.state).is_equal(Admirer.State.LEAVING)
			assert_float(uncle.position.length()).is_greater_equal(last_seen.position.length())
		last_seen = uncle

	# The real Uncle swoons for 0.6 s: 36 steps.
	assert_int(swoon_steps).is_equal(36)
	assert_bool(gone).is_true()
	# When last seen he was past the edge of the 200 × 200 screen around
	# Shireen (who stands at 0, 0), by about a sprite's height.
	var beyond_the_edge: float = maxf(absf(last_seen.position.x), absf(last_seen.position.y)) - 100.0
	assert_float(beyond_the_edge).is_greater(30.0)
	assert_int(run.snapshot().admirers_dazzled).is_greater_equal(1)


func test_a_dazzled_uncle_stops_draining_patience_at_once() -> void:
	# Three real Uncles, and a Shireen with the Patience to stand among them
	# until the first throw.
	var run := _run_with_a_late_dazzling_throw(3, TestContent.real_uncle(), TestContent.shireen_with_patience(1000.0))
	var per_step: float = 1.0 / Run.STEPS_PER_SECOND

	# All three touch her by now: 10 Patience per second each.
	_stand(run, 9 * Run.STEPS_PER_SECOND)
	assert_float(_patience_lost_in_one_step(run)).is_equal_approx(30.0 * per_step, 0.0001)

	var lost_in_the_dazzling_step: float = 0.0
	for i: int in 2 * Run.STEPS_PER_SECOND:
		lost_in_the_dazzling_step = _patience_lost_in_one_step(run)
		if run.snapshot().admirers_dazzled > 0:
			break
	var dazzled: AdmirerSnapshot = _dazzled_admirer(run.snapshot())

	# In the very step he is dazzled, he stops draining, though he still
	# stands right against her (her 6 px body plus his 7 px).
	assert_object(dazzled).is_not_null()
	assert_float(dazzled.position.length()).is_less(13.5)
	assert_bool(dazzled.touching).is_false()
	assert_float(lost_in_the_dazzling_step).is_equal_approx(20.0 * per_step, 0.0001)


func test_shireen_walks_straight_through_a_swooning_uncle() -> void:
	var run := _run_with_a_late_dazzling_throw(1)
	var dazzled: AdmirerSnapshot = _stand_until_someone_is_dazzled(run)
	var toward_him: Vector2 = dazzled.position.normalized()
	var closest: float = INF

	# He stands 13 px away. Half a second of walking (45 px) takes her right
	# over the spot while he still swoons. A chasing Uncle would be pushed
	# along in front of her.
	for i: int in 30:
		run.step(Run.TIMESTEP, toward_him)
		var snapshot := run.snapshot()
		var uncle: AdmirerSnapshot = _admirer(snapshot, dazzled.id)
		assert_vector(uncle.position).is_equal(dazzled.position)
		closest = minf(closest, snapshot.shireen_position.distance_to(uncle.position))

	assert_float(closest).is_less(1.0)


func test_the_crowd_closes_in_over_a_swooning_uncle() -> void:
	var run := _run_with_a_late_dazzling_throw(12)
	var dazzled: AdmirerSnapshot = _stand_until_someone_is_dazzled(run)
	var closest: float = INF

	# While he swoons (0.6 s), the Uncles behind him press into his place.
	for i: int in 30:
		run.step(Run.TIMESTEP, Vector2.ZERO)
		for admirer: AdmirerSnapshot in run.snapshot().admirers:
			if admirer.state == Admirer.State.CHASING:
				closest = minf(closest, admirer.position.distance_to(dazzled.position))

	# Two Uncles who block each other stay 14 px apart (12.6 in a crush).
	assert_float(closest).is_less(7.0)


# --- Stats and buffs --------------------------------------------------------

func _real_zills_run_with_buff_ranks(ranks: Dictionary[StringName, int]) -> Run:
	return _zills_run(TestContent.real(), 1, RunConfig.DEFAULT_PLAY_AREA, ranks)


func test_a_new_zills_run_has_the_base_stats_and_no_buffs_or_abilities() -> void:
	var weapon: WeaponSnapshot = _real_zills_run_with_buff_ranks({}).snapshot().weapon

	assert_str(weapon.id).is_equal("zills")
	assert_float(weapon.stats[&"damage"]).is_equal(10.0)
	assert_float(weapon.stats[&"cooldown"]).is_equal(1.2)
	assert_float(weapon.stats[&"count"]).is_equal(1.0)
	assert_float(weapon.stats[&"pierce"]).is_equal(0.0)
	assert_dict(weapon.buffs).is_equal({&"damage": 0, &"throw_rate": 0, &"count": 0, &"speed_and_pierce": 0})
	assert_array(weapon.abilities).is_empty()


func test_maxed_buff_tracks_change_the_zills_stats_as_designed() -> void:
	# Design §6.1, five ranks of each track on the real Zills.
	var weapon: WeaponSnapshot = _real_zills_run_with_buff_ranks(
		{&"damage": 5, &"throw_rate": 5, &"count": 5, &"speed_and_pierce": 5}).snapshot().weapon

	# Damage: +20% per rank, so 10 doubles.
	assert_float(weapon.stats[&"damage"]).is_equal_approx(20.0, 0.0001)
	# Throw rate: +12% per rank.
	assert_float(weapon.stats[&"rate"]).is_equal_approx(1.6, 0.0001)
	# Count: +1 zill at ranks 1, 3 and 5; +15% size at ranks 2 and 4.
	assert_float(weapon.stats[&"count"]).is_equal_approx(4.0, 0.0001)
	assert_float(weapon.stats[&"area"]).is_equal_approx(5.2, 0.0001)
	# Speed and pierce: +10% speed and +1 pierce per rank.
	assert_float(weapon.stats[&"speed"]).is_equal_approx(330.0, 0.0001)
	assert_float(weapon.stats[&"pierce"]).is_equal_approx(5.0, 0.0001)
	assert_dict(weapon.buffs).is_equal({&"damage": 5, &"throw_rate": 5, &"count": 5, &"speed_and_pierce": 5})


func test_a_track_only_gives_what_its_ranks_so_far_grant() -> void:
	# Count at rank 2: the +1 zill of rank 1 and the +15% size of rank 2.
	var weapon: WeaponSnapshot = _real_zills_run_with_buff_ranks({&"count": 2}).snapshot().weapon

	assert_float(weapon.stats[&"count"]).is_equal_approx(2.0, 0.0001)
	assert_float(weapon.stats[&"area"]).is_equal_approx(4.6, 0.0001)
	assert_float(weapon.stats[&"damage"]).is_equal(10.0)


func test_a_maxed_damage_track_dazzles_an_uncle_in_two_hits() -> void:
	var content := TestContent.weapon_against(TestContent.real_zills(), TestContent.harmless_uncle(), 1)
	var run := _zills_run(content, 5, SMALL_SCREEN, {&"damage": 5})

	# 20 damage a zill against 30 HP.
	assert_array(_hp_seen(run, 1, 3 * Run.STEPS_PER_SECOND)).is_equal([30.0, 10.0, 0.0])


func test_a_maxed_throw_rate_track_throws_every_0_75_seconds() -> void:
	var content := TestContent.weapon_against(TestContent.real_zills(), TestContent.tough_uncle(), 1)
	var run := _zills_run(content, 5, SMALL_SCREEN, {&"throw_rate": 5})

	# 1.2 s / 1.6 = 0.75 s, which is 45 steps.
	assert_array(_throw_ticks(run, 3 * Run.STEPS_PER_SECOND)).is_equal([45, 90, 135, 180])


func test_one_rank_of_throw_rate_throws_12_percent_more_often() -> void:
	var content := TestContent.weapon_against(TestContent.real_zills(), TestContent.tough_uncle(), 1)
	var run := _zills_run(content, 5, SMALL_SCREEN, {&"throw_rate": 1})

	# Unbuffed, 100 s is 83 throws (one every 1.2 s). 12% more often is 93.3.
	# The time between throws (64.29 steps) isn't a whole number of steps, so
	# the part of a step left over after each throw has to count toward the
	# next: rounding every wait up to 65 steps would give only 92.
	assert_int(_throw_ticks(run, 100 * Run.STEPS_PER_SECOND).size()).is_equal(93)


# --- The snapshot -----------------------------------------------------------

func test_the_weapon_state_is_in_the_plain_data_snapshot() -> void:
	var run := _zills_run(TestContent.weapon_against(TestContent.real_zills(), TestContent.tough_uncle(), 1), 5)
	_stand(run, 80)

	var state: Dictionary = run.snapshot().to_dict()

	assert_str(state["weapon"]["id"]).is_equal("zills")
	assert_int(state["weapon"]["attacks"]).is_equal(1)
	assert_float(state["weapon"]["stats"][&"damage"]).is_equal(10.0)
	assert_int(state["weapon"]["buffs"][&"damage"]).is_equal(0)
	assert_array(state["weapon"]["abilities"]).is_empty()
	assert_int(state["projectiles"].size()).is_equal(1)
	assert_str(state["projectiles"][0]["kind"]).is_equal("zill")
	assert_int(state["admirers_dazzled"]).is_equal(0)
	assert_str(state["admirers"][0]["state"]).is_equal("chasing")


## Throws, hits and dazzles depend on the seed (where admirers arrive) and
## the input (where Shireen walks), and on nothing else.
func test_a_zills_run_replays_identically_from_its_seed_and_inputs() -> void:
	var directions: Array[Vector2] = [Vector2.ZERO, Vector2.RIGHT, Vector2(-1, 1), Vector2.UP]
	var runs: Array[Run] = []
	for i: int in 2:
		runs.append(Run.new(RunConfig.new(TestContent.real(), 77, RunConfig.DEFAULT_PLAY_AREA, &"zills")))

	for i: int in 30 * Run.STEPS_PER_SECOND:
		@warning_ignore("integer_division")
		var direction: Vector2 = directions[(i / 45) % directions.size()]
		for run: Run in runs:
			# Cash from the dazzles levels the Zills up along the way: take
			# the first card each time (the cards are level_up_test.gd's).
			if run.snapshot().phase == Run.Phase.LEVEL_UP:
				run.choose_card(0)
			run.step(Run.TIMESTEP, direction)
		assert_dict(runs[1].snapshot().to_dict()).is_equal(runs[0].snapshot().to_dict())

	# And it was a real fight: Uncles were dazzled along the way.
	assert_int(runs[0].snapshot().admirers_dazzled).is_greater(3)


# --- Speed ------------------------------------------------------------------

## The same budget as the crowd timing tests in dowry_uncle_test.gd: 20% of
## a 60 Hz frame for a step plus the snapshot the view takes after it.
## Calibrated on the user's machine (2026-11-09, Godot 4.7.2 headless via
## run_tests.cmd): 300 Uncles under fully buffed Zills took 1,370–1,460 µs
## over seven runs, about 100 more than the same crowd with no weapon (and
## up to 1,620 while other programs kept the machine busy).
const MEASURED_STEP_USEC: float = 1450.0
const STEP_BUDGET_USEC: float = 3300.0


## The busiest the Zills get: every buff maxed (4 zills a throw, each through
## 6 admirers, a throw every 0.75 s) into a full crowd that never thins out.
func test_three_hundred_uncles_under_maxed_zills_step_within_the_time_budget() -> void:
	var content := TestContent.weapon_against(TestContent.real_zills(), TestContent.tough_uncle(), 300)
	var run := _zills_run(content, 17, RunConfig.DEFAULT_PLAY_AREA, {&"damage": 5, &"throw_rate": 5, &"count": 5, &"speed_and_pierce": 5})
	_stand(run, 15 * Run.STEPS_PER_SECOND)
	assert_int(run.snapshot().admirer_count).is_equal(300)

	var most_zills: int = 0
	var started: int = Time.get_ticks_usec()
	for i: int in 300:
		run.step(Run.TIMESTEP, Vector2.ZERO)
		most_zills = maxi(most_zills, run.snapshot().projectiles.size())
	var average_usec: float = float(Time.get_ticks_usec() - started) / 300

	print("300 admirers under maxed Zills, up to %d zills in flight: %.0f µs per step and snapshot (calibrated at %.0f, budget %.0f)" % [most_zills, average_usec, MEASURED_STEP_USEC, STEP_BUDGET_USEC])
	assert_int(most_zills).is_greater_equal(4)
	assert_float(average_usec).is_less(STEP_BUDGET_USEC)
