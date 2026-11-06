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
##     run.step(Run.TIMESTEP, Vector2.RIGHT)
##     print(run.snapshot().time)

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


func _init(config: RunConfig) -> void:
	assert(config.play_area.x > 0.0 and config.play_area.y > 0.0, "Run: play_area must be positive")
	assert(config.content.is_valid(), "Run: " + config.content.error_report())
	_config = config
	_shireen_speed = config.content.shireen.move_speed
	# The Run's private RNG. Nothing uses it yet; admirer spawns, card offers
	# and lamp rolls will draw from it so a seed replays a whole run.
	_rng = RandomNumberGenerator.new()
	_rng.seed = config.rng_seed


## Advances the run by one fixed step.
## [param delta] should be [constant TIMESTEP]; the view guarantees it.
## [param move_direction] is the player's input: which way Shireen walks.
func step(delta: float, move_direction: Vector2) -> void:
	assert(is_equal_approx(delta, TIMESTEP), "Run.step: expected the fixed timestep %f, got %f" % [TIMESTEP, delta])
	_tick += 1
	# Cap at length 1 so a diagonal like (1, 1) is no faster than straight.
	var direction: Vector2 = move_direction.limit_length(1.0)
	_shireen_position += direction * _shireen_speed * delta
	_shireen_moving = not direction.is_zero_approx()
	# Standing still keeps the old facing instead of resetting it.
	if _shireen_moving:
		_shireen_facing = direction.normalized()


## Run time comes from the tick count rather than summing floats, so it never
## drifts and two identical runs always report exactly the same value.
func snapshot() -> RunSnapshot:
	var snap := RunSnapshot.new()
	snap.time = _tick * TIMESTEP
	snap.tick = _tick
	snap.shireen_position = _shireen_position
	snap.shireen_facing = _shireen_facing
	snap.shireen_moving = _shireen_moving
	return snap
