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

## Where a run is in its life. The level-up and lamp pauses join in later
## tickets.
enum Phase {
	PLAYING,
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


func _init(config: RunConfig) -> void:
	assert(config.play_area.x > 0.0 and config.play_area.y > 0.0, "Run: play_area must be positive")
	assert(config.content.is_valid(), "Run: " + config.content.error_report())
	_config = config
	var content: ContentRegistry = config.content
	_shireen_speed = content.shireen.move_speed
	_max_patience = content.shireen.max_patience
	_patience = _max_patience
	# The Run's private RNG. Every random choice (where admirers spawn, later
	# card offers and lamp rolls) draws from it, so a seed replays a whole run.
	_rng = RandomNumberGenerator.new()
	_rng.seed = config.rng_seed

	_crowd = AdmirerCrowd.new(content.shireen.body_radius, content.max_admirer_radius())
	for id: StringName in content.admirers:
		_behaviors[id] = content.create_admirer_behavior(content.admirers[id])
	if content.spawn_ramp != null:
		_spawn_director = SpawnDirector.new(content.spawn_ramp, config.play_area, _rng)


## Advances the run by one fixed step and returns what happened during it,
## in order (most steps: nothing).
## [param delta] should be [constant TIMESTEP]; the view guarantees it.
## [param move_direction] is the player's input: which way Shireen walks.
func step(delta: float, move_direction: Vector2) -> Array[RunEvent]:
	assert(is_equal_approx(delta, TIMESTEP), "Run.step: expected the fixed timestep %f, got %f" % [TIMESTEP, delta])
	var events: Array[RunEvent] = []
	# An ended run stays exactly as it ended: the clock, Shireen and the
	# crowd all stop, so the end screen's numbers can't change under it.
	if _phase == Phase.ENDED:
		return events
	_tick += 1
	_move_shireen(delta, move_direction)
	_crowd.step(delta, _shireen_position)
	_drain_patience(delta)
	if _patience <= 0.0:
		_phase = Phase.ENDED
		_outcome = Outcome.DEFEAT
		events.append(RunEndedEvent.new(_outcome, _last_touching_type))
		return events
	# Spawn last, so a new admirer shows up exactly where the director put
	# him, just off-screen, before he takes his first step.
	_spawn_admirers(delta)
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
	for admirer: Admirer in _crowd.admirers:
		var copy := AdmirerSnapshot.new()
		copy.id = admirer.id
		copy.type_id = admirer.type.id
		copy.position = admirer.position
		copy.facing = admirer.facing
		copy.touching = admirer.touching
		snap.admirers.append(copy)
	return snap


## "playing" or "ended", for debug dumps.
static func phase_name(phase: Phase) -> String:
	return Phase.find_key(phase).to_lower()


## "none" or "defeat", for debug dumps.
static func outcome_name(outcome: Outcome) -> String:
	return Outcome.find_key(outcome).to_lower()


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
