extends GdUnitTestSuite
## Level-up buff cards, checked through the Run seam (ADR-0001): collect
## cash until the weapon levels up, look at the cards in the snapshot, pick
## one by index, and watch the weapon's buffs and stats.

## The small screen most Zills tests use: admirers arrive at most 190 px away.
const SMALL_SCREEN: Vector2 = Vector2(200, 200)


## A Zills run that levels up fast: the first throw comes at 1.2 s and then
## every 0.2 s, one dazzle a throw, against 20 Uncles worth [param cash]
## each. Shireen's pickup radius covers the whole small screen, so every bill
## flies to her at once. [param buff_ranks] starts the Zills with some tracks
## already ranked up; [param leveling] replaces the design's curve and
## fallback values; [param uncle] and [param shireen] replace the harmless
## Uncle and the wide-reaching Shireen.
func _fast_run(cash: int = 5, buff_ranks: Dictionary[StringName, int] = {}, rng_seed: int = 9, leveling: LevelingData = null, uncle: AdmirerData = TestContent.uncle_worth(cash), shireen: ShireenData = TestContent.shireen_with_pickup_radius(200.0)) -> Run:
	var content := ContentRegistry.from_data(shireen, [uncle], TestContent.steady_spawns(&"dowry_uncle", 100.0, 20), [TestContent.one_hit_zills(0.2)], leveling)
	var config := RunConfig.new(content, rng_seed, SMALL_SCREEN, &"zills")
	config.starting_buff_ranks = buff_ranks
	return Run.new(config)


## Stands still for [param ticks] steps and returns everything that happened.
func _stand(run: Run, ticks: int) -> Array[RunEvent]:
	var events: Array[RunEvent] = []
	for i: int in ticks:
		events.append_array(run.step(Run.TIMESTEP, Vector2.ZERO))
	return events


## Steps [param run] standing still until cards are up, and returns the
## events of the step that put them up.
func _stand_until_cards_are_offered(run: Run) -> Array[RunEvent]:
	for i: int in 30 * Run.STEPS_PER_SECOND:
		var events := run.step(Run.TIMESTEP, Vector2.ZERO)
		if run.snapshot().phase == Run.Phase.LEVEL_UP:
			return events
	fail("no cards were offered within 30 s")
	return []


## The ids of [param cards], in order.
func _ids(cards: Array[Card]) -> Array[StringName]:
	var ids: Array[StringName] = []
	for card: Card in cards:
		ids.append(card.id)
	return ids


# --- The pause --------------------------------------------------------------

func test_the_first_level_up_pauses_the_run_and_offers_three_buff_cards() -> void:
	# The first dazzle at 1.2 s drops 5 cash, exactly the first level-up.
	var run := _fast_run()

	var events := _stand_until_cards_are_offered(run)

	var snapshot := run.snapshot()
	assert_int(snapshot.level).is_equal(2)
	assert_int(snapshot.phase).is_equal(Run.Phase.LEVEL_UP)
	assert_int(snapshot.cards.size()).is_equal(3)
	for card: Card in snapshot.cards:
		assert_int(card.kind).is_equal(Card.Kind.BUFF)
		assert_int(card.rank).is_equal(1)
	# The level-up is announced first, then the cards for it.
	assert_int(events.size()).is_equal(2)
	assert_object(events[0]).is_instanceof(LeveledUpEvent)
	assert_object(events[1]).is_instanceof(CardsOfferedEvent)
	var offered: CardsOfferedEvent = events[1]
	assert_int(offered.level).is_equal(2)
	assert_array(_ids(offered.cards)).is_equal(_ids(snapshot.cards))


func test_nothing_moves_while_the_cards_are_up() -> void:
	var run := _fast_run()
	_stand_until_cards_are_offered(run)
	var paused: Dictionary = run.snapshot().to_dict()

	# Walking is ignored too: the view stops feeding input, but the Run
	# doesn't rely on it.
	var events: Array[RunEvent] = []
	for i: int in 2 * Run.STEPS_PER_SECOND:
		events.append_array(run.step(Run.TIMESTEP, Vector2.RIGHT))

	assert_array(events).is_empty()
	assert_dict(run.snapshot().to_dict()).is_equal(paused)
	assert_int(run.snapshot().phase).is_equal(Run.Phase.LEVEL_UP)


# --- Picking a card ---------------------------------------------------------

## A fast run (see [method _fast_run]) where every track but [param track_id]
## starts maxed, so each level-up offers that one track and nothing else.
func _run_offering_only(track_id: StringName, cash: int = 5) -> Run:
	var others: Dictionary[StringName, int] = {}
	for track: BuffTrackData in TestContent.real_zills().buff_tracks:
		if track.id != track_id:
			others[track.id] = track.max_rank
	return _fast_run(cash, others)


## Plays [param run] to its next level-up and picks the one card offered,
## which must be for [param track_id]. Returns the card.
func _level_up_and_pick(run: Run, track_id: StringName) -> Card:
	_stand_until_cards_are_offered(run)
	var cards: Array[Card] = run.snapshot().cards
	assert_int(cards.size()).is_equal(1)
	assert_str(cards[0].id).is_equal(track_id)
	run.choose_card(0)
	return cards[0]


func test_picking_a_buff_card_ranks_its_track_up_and_resumes_the_run() -> void:
	var run := _run_offering_only(&"damage")
	var card: Card = _level_up_and_pick(run, &"damage")
	var chosen_at: int = run.snapshot().tick

	var snapshot := run.snapshot()
	assert_int(card.rank).is_equal(1)
	assert_int(snapshot.weapon.buffs[&"damage"]).is_equal(1)
	assert_int(snapshot.phase).is_equal(Run.Phase.PLAYING)
	assert_array(snapshot.cards).is_empty()
	# The clock runs again. (Not necessarily for all 10 steps: with three
	# tracks maxed the Zills can level up again within them.)
	_stand(run, 10)
	assert_int(run.snapshot().tick).is_greater(chosen_at)


func test_the_damage_track_adds_20_percent_damage_a_rank() -> void:
	# Design §6.1 on the one-hit test Zills (30 damage): 36, then 42.
	var run := _run_offering_only(&"damage")

	_level_up_and_pick(run, &"damage")
	assert_float(run.snapshot().weapon.stats[&"damage"]).is_equal_approx(36.0, 0.0001)

	var second: Card = _level_up_and_pick(run, &"damage")
	assert_int(second.rank).is_equal(2)
	assert_float(run.snapshot().weapon.stats[&"damage"]).is_equal_approx(42.0, 0.0001)
	assert_int(run.snapshot().weapon.buffs[&"damage"]).is_equal(2)


func test_the_throw_rate_track_adds_12_percent_rate_a_rank() -> void:
	var run := _run_offering_only(&"throw_rate")

	_level_up_and_pick(run, &"throw_rate")

	assert_float(run.snapshot().weapon.stats[&"rate"]).is_equal_approx(1.12, 0.0001)


func test_the_count_track_adds_a_zill_at_rank_1_and_15_percent_size_at_rank_2() -> void:
	var run := _run_offering_only(&"count")

	_level_up_and_pick(run, &"count")
	var snapshot := run.snapshot()
	assert_float(snapshot.weapon.stats[&"count"]).is_equal_approx(2.0, 0.0001)
	assert_float(snapshot.weapon.stats[&"area"]).is_equal_approx(4.0, 0.0001)
	# In play: the next throw sends two zills (earlier ones may still fly).
	var seen: Dictionary[int, bool] = {}
	for zill: ProjectileSnapshot in snapshot.projectiles:
		seen[zill.id] = true
	for i: int in Run.STEPS_PER_SECOND:
		run.step(Run.TIMESTEP, Vector2.ZERO)
		if run.snapshot().weapon.attacks > snapshot.weapon.attacks:
			break
		for zill: ProjectileSnapshot in run.snapshot().projectiles:
			seen[zill.id] = true
	var thrown: int = 0
	for zill: ProjectileSnapshot in run.snapshot().projectiles:
		if not seen.has(zill.id):
			thrown += 1
	assert_int(thrown).is_equal(2)

	_level_up_and_pick(run, &"count")
	snapshot = run.snapshot()
	assert_float(snapshot.weapon.stats[&"count"]).is_equal_approx(2.0, 0.0001)
	assert_float(snapshot.weapon.stats[&"area"]).is_equal_approx(4.6, 0.0001)


func test_the_speed_and_pierce_track_adds_10_percent_speed_and_1_pierce_a_rank() -> void:
	var run := _run_offering_only(&"speed_and_pierce")

	_level_up_and_pick(run, &"speed_and_pierce")

	var snapshot := run.snapshot()
	assert_float(snapshot.weapon.stats[&"speed"]).is_equal_approx(242.0, 0.0001)
	assert_float(snapshot.weapon.stats[&"pierce"]).is_equal_approx(1.0, 0.0001)


# --- What is offered --------------------------------------------------------

func _all_maxed(snapshot: RunSnapshot) -> bool:
	for track: BuffTrackData in TestContent.real_zills().buff_tracks:
		if snapshot.weapon.buffs[track.id] < track.max_rank:
			return false
	return true


func test_every_offer_is_of_distinct_unmaxed_tracks_until_all_are_maxed() -> void:
	# Bills of 100 cash: a level-up or several a dazzle, 20 ranks to fill.
	var run := _fast_run(100)
	var picks: int = 0

	while not _all_maxed(run.snapshot()):
		if run.snapshot().phase != Run.Phase.LEVEL_UP:
			_stand_until_cards_are_offered(run)
		var snapshot := run.snapshot()
		var unmaxed: int = 0
		for track: BuffTrackData in TestContent.real_zills().buff_tracks:
			if snapshot.weapon.buffs[track.id] < track.max_rank:
				unmaxed += 1
		assert_int(snapshot.cards.size()).is_equal(mini(3, unmaxed))
		var ids: Array[StringName] = _ids(snapshot.cards)
		for card: Card in snapshot.cards:
			assert_int(card.kind).is_equal(Card.Kind.BUFF)
			assert_int(ids.count(card.id)).is_equal(1)
			# The next rank of a track that can still take one.
			assert_int(card.rank).is_equal(snapshot.weapon.buffs[card.id] + 1)
			assert_int(card.rank).is_less_equal(card.max_rank)
			assert_int(card.max_rank).is_equal(5)
		# A different pick each time, so every track gets its turn.
		run.choose_card(picks % snapshot.cards.size())
		picks += 1

	assert_int(picks).is_equal(20)
	assert_dict(run.snapshot().weapon.buffs).is_equal({&"damage": 5, &"throw_rate": 5, &"count": 5, &"speed_and_pierce": 5})


func test_a_maxed_track_is_not_offered() -> void:
	var run := _fast_run(5, {&"damage": 5})

	_stand_until_cards_are_offered(run)

	var ids: Array[StringName] = _ids(run.snapshot().cards)
	assert_int(ids.size()).is_equal(3)
	assert_array(ids).not_contains([&"damage"])


func test_several_level_ups_gained_at_once_are_offered_one_after_another() -> void:
	# One 100-cash bill is seven level-ups (5 + 8 + 11 + 14 + 17 + 20 + 23 = 98).
	var run := _fast_run(100)

	var events := _stand_until_cards_are_offered(run)

	# Every level-up is announced in that step, then the cards for the first.
	assert_int(events.size()).is_equal(8)
	for i: int in 7:
		assert_object(events[i]).is_instanceof(LeveledUpEvent)
	assert_object(events[7]).is_instanceof(CardsOfferedEvent)
	assert_int((events[7] as CardsOfferedEvent).level).is_equal(2)
	assert_int(run.snapshot().level).is_equal(8)
	assert_int(run.snapshot().cards_level).is_equal(2)
	assert_int(run.snapshot().pending_level_ups).is_equal(6)

	# Each pick brings the next level's cards straight up, until the last.
	for level: int in range(3, 9):
		var chosen := run.choose_card(0)
		assert_int(chosen.size()).is_equal(1)
		assert_object(chosen[0]).is_instanceof(CardsOfferedEvent)
		assert_int((chosen[0] as CardsOfferedEvent).level).is_equal(level)
		assert_int(run.snapshot().phase).is_equal(Run.Phase.LEVEL_UP)
		assert_int(run.snapshot().cards_level).is_equal(level)
		assert_int(run.snapshot().pending_level_ups).is_equal(8 - level)
	var last := run.choose_card(0)

	assert_array(last).is_empty()
	assert_int(run.snapshot().phase).is_equal(Run.Phase.PLAYING)
	assert_int(run.snapshot().cards_level).is_equal(0)
	assert_int(run.snapshot().pending_level_ups).is_equal(0)
	var ranks_given: int = 0
	for rank: int in run.snapshot().weapon.buffs.values():
		ranks_given += rank
	assert_int(ranks_given).is_equal(7)


# --- Once every buff is maxed -----------------------------------------------

const ALL_MAXED: Dictionary[StringName, int] = {&"damage": 5, &"throw_rate": 5, &"count": 5, &"speed_and_pierce": 5}


func test_once_every_track_is_maxed_the_cards_are_big_tip_and_sip_of_tea() -> void:
	var run := _fast_run(5, ALL_MAXED)

	_stand_until_cards_are_offered(run)

	var cards: Array[Card] = run.snapshot().cards
	assert_int(cards.size()).is_equal(2)
	assert_int(cards[0].kind).is_equal(Card.Kind.BIG_TIP)
	assert_str(cards[0].id).is_equal(Card.BIG_TIP_ID)
	assert_str(cards[0].name).is_equal("Big tip")
	assert_int(cards[1].kind).is_equal(Card.Kind.SIP_OF_TEA)
	assert_str(cards[1].id).is_equal(Card.SIP_OF_TEA_ID)
	assert_str(cards[1].name).is_equal("Sip of tea")
	for card: Card in cards:
		assert_int(card.rank).is_equal(0)
		assert_int(card.max_rank).is_equal(0)


func test_big_tip_pays_bonus_cash_into_the_level_bar() -> void:
	# A flat 50 cash a level, so the tip can't level her up again at once.
	# The tip itself comes from the leveling data: 7 here, 10 in the game.
	var curve := TestContent.leveling(50, 0)
	curve.big_tip_cash = 7
	var run := _fast_run(5, ALL_MAXED, 9, curve)
	_stand_until_cards_are_offered(run)
	var before := run.snapshot()
	assert_int(before.level_cash).is_equal(0)

	run.choose_card(0)

	var after := run.snapshot()
	assert_int(after.cash_collected).is_equal(before.cash_collected + 7)
	assert_int(after.level_cash).is_equal(7)
	assert_int(after.level).is_equal(before.level)
	assert_int(after.phase).is_equal(Run.Phase.PLAYING)


func test_a_big_tip_worth_a_level_brings_the_next_cards_up() -> void:
	# The design's curve: level 2 to 3 takes 8 cash, and the real tip is 10.
	var run := _fast_run(5, ALL_MAXED)
	_stand_until_cards_are_offered(run)
	assert_int(run.snapshot().level).is_equal(2)

	var events := run.choose_card(0)

	assert_int(events.size()).is_equal(2)
	assert_object(events[0]).is_instanceof(LeveledUpEvent)
	assert_object(events[1]).is_instanceof(CardsOfferedEvent)
	var snapshot := run.snapshot()
	assert_int(snapshot.level).is_equal(3)
	assert_int(snapshot.level_cash).is_equal(2)
	assert_int(snapshot.phase).is_equal(Run.Phase.LEVEL_UP)
	assert_int(snapshot.cards.size()).is_equal(2)


func test_sip_of_tea_restores_patience_from_the_leveling_data() -> void:
	# Real Uncles drain 10 Patience a second each. They reach Shireen after
	# about 5 s (190 px at 40 px/s). The maxed Zills (four 60-damage zills,
	# throw rate 1.6) first throw at 12.5 s with a 20 s cooldown, so by the
	# level-up twenty Uncles have been draining her for about 7 s. With 5000
	# Patience she lasts, and the sip has room under her maximum.
	var curve := TestContent.leveling(150, 0)
	curve.sip_of_tea_patience = 25.0
	var shireen: ShireenData = TestContent.shireen_with_patience(5000.0)
	shireen.pickup_radius = 200.0
	var uncle: AdmirerData = TestContent.real_uncle().duplicate()
	uncle.cash = 100
	var zills: WeaponData = TestContent.zills_with({&"cooldown": 20.0, &"damage": 30.0})
	var content := ContentRegistry.from_data(shireen, [uncle], TestContent.steady_spawns(&"dowry_uncle", 100.0, 20), [zills], curve)
	var config := RunConfig.new(content, 9, SMALL_SCREEN, &"zills")
	config.starting_buff_ranks = ALL_MAXED
	var run := Run.new(config)
	_stand_until_cards_are_offered(run)
	var before: float = run.snapshot().patience
	assert_float(run.snapshot().time).is_between(12.0, 14.0)
	assert_float(before).is_between(100.0, 4975.0)
	assert_int(run.snapshot().cards[1].kind).is_equal(Card.Kind.SIP_OF_TEA)

	run.choose_card(1)

	assert_float(run.snapshot().patience).is_equal_approx(before + 25.0, 0.0001)


func test_sip_of_tea_never_takes_patience_past_her_maximum() -> void:
	var run := _fast_run(5, ALL_MAXED)
	_stand_until_cards_are_offered(run)
	assert_float(run.snapshot().patience).is_equal(100.0)

	run.choose_card(1)

	assert_float(run.snapshot().patience).is_equal(100.0)


# --- Ability levels ---------------------------------------------------------

func test_level_5_offers_buff_cards_while_the_weapon_has_no_abilities() -> void:
	# Design §5 makes 5, 10 and 15 ability levels. The Zills' abilities
	# arrive with ticket 12; until then those levels fall back to buffs.
	var run := _fast_run(100)
	_stand_until_cards_are_offered(run)
	for level: int in range(3, 6):
		var events := run.choose_card(0)
		assert_int((events[0] as CardsOfferedEvent).level).is_equal(level)

	var cards: Array[Card] = run.snapshot().cards
	assert_int(cards.size()).is_equal(3)
	for card: Card in cards:
		assert_int(card.kind).is_equal(Card.Kind.BUFF)


func test_the_ability_levels_come_from_data() -> void:
	# With no ability levels at all, level 5 is a buff level like any other,
	# which is all that can be told apart until abilities exist.
	var curve := TestContent.leveling(5, 3)
	curve.ability_levels = PackedInt32Array()
	var run := _fast_run(100, {}, 9, curve)
	_stand_until_cards_are_offered(run)
	for level: int in range(3, 6):
		run.choose_card(0)

	for card: Card in run.snapshot().cards:
		assert_int(card.kind).is_equal(Card.Kind.BUFF)


# --- What the cards say -----------------------------------------------------

## The card for [param track_id] among [param cards], or null.
func _card_for(cards: Array[Card], track_id: StringName) -> Card:
	for card: Card in cards:
		if card.id == track_id:
			return card
	return null


func test_a_buff_card_names_its_track_its_next_rank_and_what_changes() -> void:
	# Design §6.1, in the words of the real Zills data.
	var run := _fast_run(100)
	_stand_until_cards_are_offered(run)
	var seen: Dictionary[StringName, Card] = {}

	# Seven level-ups queued: enough picks to see every track once.
	while seen.size() < 4 and run.snapshot().phase == Run.Phase.LEVEL_UP:
		for card: Card in run.snapshot().cards:
			if not seen.has(card.id):
				seen[card.id] = card
		# Pick a card whose track has been seen, so the others stay at rank 0.
		var pick: int = 0
		for i: int in run.snapshot().cards.size():
			if seen.has(run.snapshot().cards[i].id):
				pick = i
		run.choose_card(pick)

	assert_int(seen.size()).is_equal(4)
	assert_str(seen[&"damage"].name).is_equal("Damage")
	assert_str(seen[&"damage"].description).is_equal("+20% damage")
	assert_str(seen[&"throw_rate"].name).is_equal("Throw rate")
	assert_str(seen[&"throw_rate"].description).is_equal("+12% throw rate")
	assert_str(seen[&"count"].name).is_equal("Count")
	assert_str(seen[&"count"].description).is_equal("+1 zill")
	assert_str(seen[&"speed_and_pierce"].name).is_equal("Speed and pierce")
	assert_str(seen[&"speed_and_pierce"].description).is_equal("+10% zill speed, +1 pierce")
	for card: Card in seen.values():
		assert_int(card.rank).is_equal(1)
		assert_int(card.max_rank).is_equal(5)


func test_a_count_card_at_rank_2_says_only_what_rank_2_changes() -> void:
	var run := _run_offering_only(&"count")
	_level_up_and_pick(run, &"count")
	_stand_until_cards_are_offered(run)

	var card: Card = run.snapshot().cards[0]
	assert_int(card.rank).is_equal(2)
	assert_str(card.description).is_equal("+15% zill size")


func test_a_change_with_no_words_of_its_own_is_described_from_its_numbers() -> void:
	# A designer who adds a modifier without a description still gets a
	# readable card: the stat's name and the amount.
	var zills: WeaponData = TestContent.real_zills().duplicate(true)
	for track: BuffTrackData in zills.buff_tracks:
		for modifier: StatModifierData in track.modifiers:
			modifier.description = ""
	var others: Dictionary[StringName, int] = {&"damage": 5, &"throw_rate": 5, &"count": 5}
	var shireen := TestContent.shireen_with_pickup_radius(200.0)
	var content := ContentRegistry.from_data(shireen, [TestContent.uncle_worth(5)], TestContent.steady_spawns(&"dowry_uncle", 100.0, 20), [zills])
	var config := RunConfig.new(content, 9, SMALL_SCREEN, &"zills")
	config.starting_buff_ranks = others
	var run := Run.new(config)

	_stand_until_cards_are_offered(run)

	assert_str(run.snapshot().cards[0].description).is_equal("+10% speed, +1 pierce")


func test_the_fallback_cards_say_what_they_give() -> void:
	var run := _fast_run(5, ALL_MAXED)

	_stand_until_cards_are_offered(run)

	var cards: Array[Card] = run.snapshot().cards
	assert_str(cards[0].description).is_equal("+10 cash")
	assert_str(cards[1].description).is_equal("+30 Patience")


# --- Determinism and the state dump -----------------------------------------

## Plays [param run] to its next cards and picks the one at [param index],
## returning the cards it chose from in plain-data form.
func _next_offer_then_pick(run: Run, index: int) -> Array:
	_stand_until_cards_are_offered(run)
	var cards: Array = run.snapshot().to_dict()["cards"]
	run.choose_card(index)
	return cards


func test_the_same_seed_and_picks_offer_the_same_cards() -> void:
	var first := _fast_run(5, {}, 77)
	var second := _fast_run(5, {}, 77)

	for i: int in 6:
		var pick: int = i % 3
		var offered: Array = _next_offer_then_pick(first, pick)
		assert_array(_next_offer_then_pick(second, pick)).is_equal(offered)
		assert_dict(second.snapshot().to_dict()).is_equal(first.snapshot().to_dict())


func test_another_seed_offers_other_cards_at_some_point() -> void:
	# The offers are random, not a fixed rotation: over six level-ups two
	# seeds disagree somewhere. (Both are checked distinct and unmaxed in
	# the offer tests.)
	var first := _fast_run(5, {}, 77)
	var second := _fast_run(5, {}, 78)
	var differed: bool = false

	for i: int in 6:
		var pick: int = i % 3
		if _next_offer_then_pick(first, pick) != _next_offer_then_pick(second, pick):
			differed = true

	assert_bool(differed).is_true()


## The F12 state dump is built from the snapshot's plain-data form (RunView).
func test_the_state_dump_reports_the_cards_and_the_buffs() -> void:
	var run := _fast_run(100, {&"damage": 2})
	_stand_until_cards_are_offered(run)

	var state: Dictionary = run.snapshot().to_dict()

	assert_str(state["phase"]).is_equal("level_up")
	assert_int(state["cards_level"]).is_equal(2)
	assert_int(state["pending_level_ups"]).is_equal(6)
	var cards: Array = state["cards"]
	assert_int(cards.size()).is_equal(3)
	for card: Dictionary in cards:
		assert_str(card["kind"]).is_equal("buff")
		assert_array(card.keys()).contains_exactly_in_any_order(["kind", "id", "name", "rank", "max_rank", "description"])
	var weapon: Dictionary = state["weapon"]
	assert_int(weapon["buffs"][&"damage"]).is_equal(2)

	run.choose_card(0)

	state = run.snapshot().to_dict()
	assert_int(state["pending_level_ups"]).is_equal(5)
	assert_int((state["cards"] as Array).size()).is_equal(3)
