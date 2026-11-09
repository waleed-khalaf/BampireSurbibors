class_name RunView
extends Node2D
## The view for one Run. It holds no gameplay rules: it owns a Run, turns real
## frame time into fixed 60 Hz steps, feeds in keyboard input and draws the
## Run's snapshot: Shireen, the admirers, her zills in flight, the hearts
## over dazzled admirers, the sand and props around them, and the run timer.

## If a frame takes very long (a hitch, the window being dragged), don't try to
## catch up with hundreds of steps at once; drop the excess time instead.
const MAX_STEPS_PER_FRAME: int = 5

## Every run uses the Zills until the weapon select screen exists (ticket 09).
const WEAPON_ID: StringName = &"zills"

var _run: Run
var _rng_seed: int
## Real time received from the engine that hasn't been simulated yet.
var _accumulator: float = 0.0
## The latest snapshot, and the one a step before it. Drawing blends between
## the two, so everyone glides smoothly on screens faster than 60 Hz.
var _snapshot: RunSnapshot
var _previous: RunSnapshot

@onready var _sand: EndlessSand = %Sand
@onready var _props: PropScatter = %Props
@onready var _shireen: ShireenSprite = %Shireen
@onready var _admirers: AdmirerRenderer = %Admirers
@onready var _projectiles: ProjectileRenderer = %Projectiles
@onready var _heart_pops: HeartPopRenderer = %HeartPops
@onready var _camera: Camera2D = %Camera
@onready var _timer_label: Label = %TimerLabel
@onready var _error_label: Label = %ErrorLabel


func _ready() -> void:
	var content := ContentRegistry.load_default()
	if not content.is_valid():
		_stop_with_content_errors(content)
		return

	var play_area: Vector2 = _read_play_area()
	# Each run gets a fresh random seed. The seed is what makes a run
	# reproducible, so the debug capture records it.
	_rng_seed = randi()
	_run = Run.new(RunConfig.new(content, _rng_seed, play_area, WEAPON_ID))
	_snapshot = _run.snapshot()
	_previous = _snapshot
	_sand.view_size = play_area
	_props.view_size = play_area
	DebugCapture.register_provider("Run", _debug_state)
	_render(0.0)


func _exit_tree() -> void:
	DebugCapture.unregister_provider("Run")


## The Run's state for state.txt (see src/debug/debug_capture.gd). It reads
## the latest snapshot, so it shows exactly what was on screen.
func _debug_state() -> Dictionary:
	var state: Dictionary = {
		"run_time": format_run_time(_snapshot.time),
		"seed": _rng_seed,
	}
	state.merge(_snapshot.to_dict())
	return state


func _process(delta: float) -> void:
	_accumulator += delta
	var steps: int = 0
	while _accumulator >= Run.TIMESTEP and steps < MAX_STEPS_PER_FRAME:
		_previous = _snapshot
		_run.step(Run.TIMESTEP, _read_move_direction())
		_snapshot = _run.snapshot()
		_accumulator -= Run.TIMESTEP
		steps += 1
	if steps == MAX_STEPS_PER_FRAME:
		_accumulator = minf(_accumulator, Run.TIMESTEP)
	_render(delta)


func _render(delta: float) -> void:
	# How far we are between the last step and the next one, from 0 to 1.
	var blend: float = _accumulator / Run.TIMESTEP
	# Round to whole pixels so the art stays crisp. The camera sits exactly on
	# Shireen, so she never jitters against the screen while the world scrolls.
	var shown: Vector2 = _previous.shireen_position.lerp(_snapshot.shireen_position, blend).round()
	_shireen.position = shown
	_camera.position = shown
	_shireen.show_state(_snapshot, delta)
	_admirers.show_admirers(_snapshot, _previous, blend, delta)
	_projectiles.show_projectiles(_snapshot, _previous, blend, delta)
	_heart_pops.show_hearts(_snapshot)
	_sand.follow(shown)
	_props.follow(shown)
	_timer_label.text = format_run_time(_snapshot.time)


## Broken content stops the game with a message saying what to fix, instead
## of a crash somewhere deep inside the Run.
func _stop_with_content_errors(content: ContentRegistry) -> void:
	push_error(content.error_report())
	_error_label.text = content.error_report()
	_error_label.visible = true
	_timer_label.visible = false
	_shireen.visible = false
	set_process(false)


## The base resolution from the project settings (Display > Window > Size).
## The view reads it so the Run gets it as data and never asks the engine.
func _read_play_area() -> Vector2:
	return Vector2(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height"),
	)


## Keyboard only (WASD or arrows). get_vector already caps diagonals at
## length 1; the Run caps them again, so the rule doesn't depend on the view.
func _read_move_direction() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


## Formats seconds as M:SS, e.g. 83.4 -> "1:23".
static func format_run_time(seconds: float) -> String:
	var whole: int = floori(seconds)
	@warning_ignore("integer_division")
	return "%d:%02d" % [whole / 60, whole % 60]
