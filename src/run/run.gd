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
##     var run := Run.new(RunConfig.new(42))
##     run.step(Run.TIMESTEP, Vector2.RIGHT)
##     print(run.snapshot().time)

## The fixed simulation rate. The view turns real frame time into steps of
## exactly this size, so a run plays out the same on fast and slow machines.
const STEPS_PER_SECOND: int = 60
const TIMESTEP: float = 1.0 / STEPS_PER_SECOND

var _config: RunConfig
var _rng: RandomNumberGenerator
var _tick: int = 0


func _init(config: RunConfig) -> void:
	assert(config.play_area.x > 0.0 and config.play_area.y > 0.0, "Run: play_area must be positive")
	_config = config
	# The Run's private RNG. Nothing uses it yet; admirer spawns, card offers
	# and lamp rolls will draw from it so a seed replays a whole run.
	_rng = RandomNumberGenerator.new()
	_rng.seed = config.rng_seed


## Advances the run by one fixed step.
## [param delta] should be [constant TIMESTEP]; the view guarantees it.
## [param _move_direction] is the player's input. It is unused until Shireen
## walks (ticket 02), hence the underscore that silences the unused warning.
func step(delta: float, _move_direction: Vector2) -> void:
	assert(is_equal_approx(delta, TIMESTEP), "Run.step: expected the fixed timestep %f, got %f" % [TIMESTEP, delta])
	_tick += 1


## Run time comes from the tick count rather than summing floats, so it never
## drifts and two identical runs always report exactly the same value.
func snapshot() -> RunSnapshot:
	return RunSnapshot.new(_tick * TIMESTEP, _tick)
