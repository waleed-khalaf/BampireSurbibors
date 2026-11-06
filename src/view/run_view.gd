class_name RunView
extends Node2D
## The view for one Run. It holds no gameplay rules: it owns a Run, turns real
## frame time into fixed 60 Hz steps, feeds in keyboard input and draws the
## Run's snapshot. Right now "drawing" is just the run timer.

## If a frame takes very long (a hitch, the window being dragged), don't try to
## catch up with hundreds of steps at once; drop the excess time instead.
const MAX_STEPS_PER_FRAME: int = 5

var _run: Run
## Real time received from the engine that hasn't been simulated yet.
var _accumulator: float = 0.0

@onready var _timer_label: Label = %TimerLabel


func _ready() -> void:
	# Each run gets a fresh random seed. The seed is what makes a run
	# reproducible, so later the debug capture will record it.
	var rng_seed: int = randi()
	_run = Run.new(RunConfig.new(rng_seed, _read_play_area()))
	_update_timer_label()


func _process(delta: float) -> void:
	_accumulator += delta
	var steps: int = 0
	while _accumulator >= Run.TIMESTEP and steps < MAX_STEPS_PER_FRAME:
		_run.step(Run.TIMESTEP, _read_move_direction())
		_accumulator -= Run.TIMESTEP
		steps += 1
	if steps == MAX_STEPS_PER_FRAME:
		_accumulator = minf(_accumulator, Run.TIMESTEP)
	_update_timer_label()


## The base resolution from the project settings (Display > Window > Size).
## The view reads it so the Run gets it as data and never asks the engine.
func _read_play_area() -> Vector2:
	return Vector2(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height"),
	)


## Keyboard only (WASD or arrows). get_vector already caps diagonals at
## length 1, so moving diagonally is not faster.
func _read_move_direction() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


func _update_timer_label() -> void:
	_timer_label.text = format_run_time(_run.snapshot().time)


## Formats seconds as M:SS, e.g. 83.4 -> "1:23".
static func format_run_time(seconds: float) -> String:
	var whole: int = floori(seconds)
	@warning_ignore("integer_division")
	return "%d:%02d" % [whole / 60, whole % 60]
