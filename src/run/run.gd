class_name Run
extends RefCounted
## The Run simulation: every gameplay rule for one run lives here (ADR-0001).
##
## It is a plain object, not a scene-tree node, so tests can build one, step it
## and check its snapshot without opening a window. To stay deterministic it
## never reads wall-clock time, input, the scene tree or engine singletons;
## the view passes in everything it needs.
##
## Usage:
##     var run := Run.new(RunConfig.new(ContentRegistry.load_default(), 42))
##     var events := run.step(Run.TIMESTEP, Vector2.RIGHT)
##     print(run.snapshot().time)

## Where a run is in its life. The lamp pause joins in ticket 20.
enum Phase {
	PLAYING,
	## Paused with level-up cards up: steps do nothing until
	## [method choose_card].
	LEVEL_UP,
	## Over for good: steps do nothing any more.
	ENDED,
}

## How a run ended. Victory joins with the Yacht Sheikh (ticket 19).
enum Outcome {
	## Still being played.
	NONE,
	## Shireen's Patience ran out: "You said yes."
	DEFEAT,
}

## The fixed simulation rate. The view turns real frame time into steps of
## exactly this size, so a run plays out the same on fast and slow machines.
const STEPS_PER_SECOND: int = 60
const TIMESTEP: float = 1.0 / STEPS_PER_SECOND

var _config: RunConfig
var _rng: RandomNumberGenerator
var _tick: int = 0
var _shireen_speed: float
var _shireen_position: Vector2 = Vector2.ZERO
var _shireen_facing: Vector2 = Vector2.RIGHT
var _shireen_moving: bool = false
var _max_patience: float
var _patience: float
var _phase: Phase = Phase.PLAYING
var _outcome: Outcome = Outcome.NONE
## The type of the admirer who touched her most recently, or empty if nobody
## has yet. On a defeat it's the one who took the last of her Patience: who
## she said yes to.
var _last_touching_type: StringName = &""

var _crowd: AdmirerCrowd
## Null when the content has no spawn ramp (some test content): no admirers.
var _spawn_director: SpawnDirector
## One behavior object per admirer type, shared by all admirers of that type.
var _behaviors: Dictionary[StringName, AdmirerBehavior] = {}
var _last_admirer_id: int = 0

## The run's one weapon. Null when the config picks none (some tests).
var _weapon: WeaponBehavior

## The cash and tea on the sand, and the pool their records come from.
var _pickups: PickupField
var _pickup_data: PickupData
var _leveling: LevelingData
## All the cash she has collected this run, for the end screen.
var _cash_collected: int = 0
var _level: int = 1
## The cash collected toward the next level, the level bar's fill.
var _level_cash: int = 0

## Makes the cards for each level-up. Null when the run has no weapon: then
## level-ups pass without a choice.
var _card_generator: CardGenerator
## The cards up right now, empty unless the phase is LEVEL_UP, and the
## level they are for (0 with none up).
var _cards: Array[Card] = []
var _cards_level: int = 0
## The levels reached whose cards haven't been offered yet, lowest first.
## A big bill can be worth several levels, and each gets its own choice.
var _pending_level_ups: Array[int] = []


func _init(config: RunConfig) -> void:
	assert(config.play_area.x > 0.0 and config.play_area.y > 0.0, "Run: play_area must be positive")
	assert(config.content.is_valid(), "Run: " + config.content.error_report())
	_config = config
	var content: ContentRegistry = config.content
	_shireen_speed = content.shireen.move_speed
	_max_patience = content.shireen.max_patience
	_patience = _max_patience
	_pickup_data = content.pickups
	_leveling = content.leveling
	_pickups = PickupField.new(content.shireen.body_radius, content.shireen.pickup_radius, _pickup_data.cash_fly_speed, _pickup_data.tea_radius)
	# The Run's private RNG. Every random choice (where admirers spawn, tea
	# drops, later card offers and lamp rolls) draws from it, so a seed
	# replays a whole run.
	_rng = RandomNumberGenerator.new()
	_rng.seed = config.rng_seed

	_crowd = AdmirerCrowd.new(content.shireen.body_radius, content.max_admirer_radius(), config.play_area)
	for id: StringName in content.admirers:
		_behaviors[id] = content.create_admirer_behavior(content.admirers[id])
	if content.spawn_ramp != null:
		_spawn_director = SpawnDirector.new(content.spawn_ramp, config.play_area, _rng)
	if config.weapon_id != &"":
		assert(content.weapons.has(config.weapon_id), "Run: the content has no weapon called \"%s\"" % config.weapon_id)
		_weapon = content.create_weapon_behavior(content.weapons[config.weapon_id])
		for track_id: StringName in config.starting_buff_ranks:
			_weapon.set_buff_rank(track_id, config.starting_buff_ranks[track_id])
		_card_generator = CardGenerator.new(_weapon, _leveling, _rng)


## Advances the run by one fixed step and returns what happened during it,
## in order (most steps: nothing).
## [param delta] should be [constant TIMESTEP]; the view guarantees it.
## [param move_direction] is the player's input: which way Shireen walks.
func step(delta: float, move_direction: Vector2) -> Array[RunEvent]:
	assert(is_equal_approx(delta, TIMESTEP), "Run.step: expected the fixed timestep %f, got %f" % [TIMESTEP, delta])
	var events: Array[RunEvent] = []
	# An ended run stays exactly as it ended: the clock, Shireen and the
	# crowd all stop, so the end screen's numbers can't change under it.
	# A run with cards up waits the same way: the player has all the time
	# they want to choose (spec story 29).
	if _phase != Phase.PLAYING:
		return events
	_tick += 1
	_move_shireen(delta, move_direction)
	_crowd.step(delta, _shireen_position)
	# The weapon goes after the crowd, so it aims at where admirers are now,
	# and before the drain, so an admirer dazzled in this step drains
	# nothing more.
	if _weapon != null:
		_weapon.step(delta, _shireen_position, _shireen_facing, _crowd)
	_drop_from_dazzled()
	# Pickups before the drain, so a cup of tea picked up in the step her
	# Patience would have run out saves her.
	_collect_pickups(delta, events)
	_drain_patience(delta)
	if _patience <= 0.0:
		_phase = Phase.ENDED
		_outcome = Outcome.DEFEAT
		# A level gained in the same step gets no cards: the run is over.
		_pending_level_ups.clear()
		events.append(RunEndedEvent.new(_outcome, _last_touching_type))
		return events
	# Spawn last, so a new admirer shows up exactly where the director put
	# him, just off-screen, before he takes his first step.
	_spawn_admirers(delta)
	# The step that leveled up finishes in full, then the run pauses on the
	# cards. Everything else in it already happened, so what the screen
	# freezes on is a whole step.
	if not _pending_level_ups.is_empty():
		_offer_cards(events)
	return events


## Picks the card at [param index] among the ones up (see
## [member RunSnapshot.cards]) and applies it. Only while the phase is
## LEVEL_UP. The run goes back to playing, or straight on to the cards for
## the next level-up waiting behind this one; the events returned say which.
func choose_card(index: int) -> Array[RunEvent]:
	assert(_phase == Phase.LEVEL_UP, "Run.choose_card: no cards are up")
	assert(index >= 0 and index < _cards.size(), "Run.choose_card: there is no card %d, only %d cards are up" % [index, _cards.size()])
	var events: Array[RunEvent] = []
	var card: Card = _cards[index]
	_cards = []
	_cards_level = 0
	match card.kind:
		Card.Kind.BUFF:
			_weapon.set_buff_rank(card.id, card.rank)
		Card.Kind.ABILITY:
			for ability: AbilityData in _weapon.data.abilities:
				if ability.id == card.id:
					_weapon.gain_ability(ability, _config.content.create_ability_behavior(ability))
		Card.Kind.BIG_TIP:
			# Cash like any other: it fills the level bar, and a tip worth a
			# level queues another level-up, with its own cards.
			_collect_cash(_leveling.big_tip_cash, events)
		Card.Kind.SIP_OF_TEA:
			_patience = minf(_patience + _leveling.sip_of_tea_patience, _max_patience)
	if _pending_level_ups.is_empty():
		_phase = Phase.PLAYING
	else:
		_offer_cards(events)
	return events


## Run time comes from the tick count rather than summing floats, so it never
## drifts and two identical runs always report exactly the same value.
func snapshot() -> RunSnapshot:
	var snap := RunSnapshot.new()
	snap.time = _time()
	snap.tick = _tick
	snap.shireen_position = _shireen_position
	snap.shireen_facing = _shireen_facing
	snap.shireen_moving = _shireen_moving
	snap.patience = _patience
	snap.max_patience = _max_patience
	snap.phase = _phase
	snap.outcome = _outcome
	snap.last_touching_type = _last_touching_type
	# The chasing admirers first, then the dazzled ones. One loop over both
	# lists, with the copy written out here: a function call per admirer
	# costs about as much as the copy itself, and with 300 admirers the
	# view pays for it every frame.
	for list: Array[Admirer] in [_crowd.admirers, _crowd.dazzled]:
		for admirer: Admirer in list:
			var copy := AdmirerSnapshot.new()
			copy.id = admirer.id
			copy.type_id = admirer.type.id
			copy.position = admirer.position
			copy.facing = admirer.facing
			copy.touching = admirer.touching
			copy.hp = admirer.hp
			copy.state = admirer.state
			copy.state_time = admirer.state_time
			snap.admirers.append(copy)
	snap.admirer_count = _crowd.size()
	snap.admirers_dazzled = _crowd.dazzled_count
	snap.cash_collected = _cash_collected
	snap.level = _level
	snap.level_cash = _level_cash
	snap.level_cash_needed = _leveling.cash_to_level_up_from(_level)
	for card: Card in _cards:
		snap.cards.append(card.copy())
	snap.cards_level = _cards_level
	snap.pending_level_ups = _pending_level_ups.size()
	for pickup: Pickup in _pickups.pickups:
		var copy := PickupSnapshot.new()
		copy.id = pickup.id
		copy.kind = pickup.kind
		copy.position = pickup.position
		copy.value = pickup.value
		copy.state = pickup.state
		snap.pickups.append(copy)
	if _weapon != null:
		snap.weapon = _weapon.snapshot()
		_weapon.add_projectiles_to(snap.projectiles)
	return snap


## "playing", "level_up" or "ended", for debug dumps.
static func phase_name(phase: Phase) -> String:
	var key: String = Phase.find_key(phase)
	return key.to_lower()


## "none" or "defeat", for debug dumps.
static func outcome_name(outcome: Outcome) -> String:
	var key: String = Outcome.find_key(outcome)
	return key.to_lower()


func _time() -> float:
	return _tick * TIMESTEP


func _move_shireen(delta: float, move_direction: Vector2) -> void:
	# Cap at length 1 so a diagonal like (1, 1) is no faster than straight.
	var direction: Vector2 = move_direction.limit_length(1.0)
	_shireen_position += direction * _shireen_speed * delta
	_shireen_moving = not direction.is_zero_approx()
	# Standing still keeps the old facing instead of resetting it.
	if _shireen_moving:
		_shireen_facing = direction.normalized()


## Every admirer touching Shireen drains her Patience at his type's rate.
## Only chasing admirers can touch her: a dazzled one left the chasing crowd
## the moment he was dazzled, however close he still stands.
## They take their turns in spawn order, and the draining stops the moment
## nothing is left. So when it runs out, the last-touching type is the
## admirer who took the last of it.
func _drain_patience(delta: float) -> void:
	for admirer: Admirer in _crowd.admirers:
		if not admirer.touching:
			continue
		_patience -= admirer.type.drain_per_second * delta
		_last_touching_type = admirer.type.id
		if _patience <= 0.0:
			_patience = 0.0
			return


## Every admirer dazzled this step drops his cash where he stands (design
## §7), and now and then a cup of karkadeh tea with it (design §4). An
## admirer worth nothing drops no cash, but can still drop tea.
func _drop_from_dazzled() -> void:
	for admirer: Admirer in _crowd.dazzled_this_step:
		if admirer.type.cash > 0:
			_pickups.drop(Pickup.Kind.CASH, admirer.position, admirer.type.cash)
		# One roll of the Run's RNG per dazzle, chance or no chance, so the
		# tea data never changes where later admirers spawn for a seed.
		if _rng.randf() < _pickup_data.tea_drop_chance:
			_pickups.drop(Pickup.Kind.TEA, admirer.position, 0)


## Moves the pickups and takes in what Shireen collected: cash fills the
## level bar, each level-up being an event, and tea restores Patience.
func _collect_pickups(delta: float, events: Array[RunEvent]) -> void:
	_pickups.step(delta, _shireen_position)
	for pickup: Pickup in _pickups.collected:
		if pickup.kind == Pickup.Kind.TEA:
			_patience = minf(_patience + _pickup_data.tea_patience, _max_patience)
		else:
			_collect_cash(pickup.value, events)


## Takes in [param cash]: it counts toward the run's total and the next
## level, and each level-up it pays for is an event and, with a weapon to
## buff, a card choice to come.
func _collect_cash(cash: int, events: Array[RunEvent]) -> void:
	_cash_collected += cash
	_level_cash += cash
	# A big bill can be worth several levels at once.
	while _level_cash >= _leveling.cash_to_level_up_from(_level):
		_level_cash -= _leveling.cash_to_level_up_from(_level)
		_level += 1
		events.append(LeveledUpEvent.new(_level))
		if _card_generator != null:
			_pending_level_ups.append(_level)


## Pauses the run on the cards for the next waiting level-up.
func _offer_cards(events: Array[RunEvent]) -> void:
	_cards_level = _pending_level_ups.pop_front()
	_cards = _card_generator.offer(_cards_level)
	_phase = Phase.LEVEL_UP
	# Copies, like the snapshot's: the view can't change the Run's cards.
	var offered: Array[Card] = []
	for card: Card in _cards:
		offered.append(card.copy())
	events.append(CardsOfferedEvent.new(_cards_level, offered))


func _spawn_admirers(delta: float) -> void:
	if _spawn_director == null:
		return
	var count: int = _spawn_director.spawns_due(delta, _time(), _crowd.size())
	# Most steps spawn nobody, so don't look the type up for nothing.
	if count == 0:
		return
	var type: AdmirerData = _config.content.admirers[_spawn_director.admirer_id()]
	for i: int in count:
		_last_admirer_id += 1
		var position: Vector2 = _spawn_director.spawn_position(_shireen_position)
		var admirer := Admirer.new(_last_admirer_id, type, _behaviors[type.id], position)
		# Face her from the start, so he doesn't walk in backwards for a frame.
		admirer.facing = (_shireen_position - position).normalized()
		_crowd.add(admirer)
