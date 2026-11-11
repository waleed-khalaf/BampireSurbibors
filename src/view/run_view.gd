class_name RunView
extends Node2D
## The view for one Run. It holds no gameplay rules: it owns a Run, turns real
## frame time into fixed 60 Hz steps, feeds in keyboard input and draws the
## Run's snapshot: Shireen, the admirers, her zills in flight, the hearts
## over dazzled admirers, the cash and tea on the sand, the sand and props
## around them, the run timer, the Patience bar and the level bar. When the
## Run pauses on a level-up, it shows the card screen and hands the pick
## back to the Run. When the Run reports that it ended, it freezes the
## picture, shows the "You said yes." screen and starts a new run on Enter.

## If a frame takes very long (a hitch, the window being dragged), don't try to
## catch up with hundreds of steps at once; drop the excess time instead.
const MAX_STEPS_PER_FRAME: int = 5

## Every run uses the Zills until the weapon select screen exists (ticket 09).
const WEAPON_ID: StringName = &"zills"

var _run: Run
var _rng_seed: int
## The weapon's display name, for the level-up screen's title.
var _weapon_name: String
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
@onready var _pickups: PickupRenderer = %Pickups
@onready var _camera: Camera2D = %Camera
@onready var _timer_label: Label = %TimerLabel
@onready var _patience_bar: HudBar = %PatienceBar
@onready var _level_bar: HudBar = %LevelBar
@onready var _level_label: Label = %LevelLabel
@onready var _level_up_screen: LevelUpScreen = %LevelUpScreen
@onready var _defeat_screen: DefeatScreen = %DefeatScreen
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
	_weapon_name = content.weapons[WEAPON_ID].display_name
	_snapshot = _run.snapshot()
	_previous = _snapshot
	_sand.view_size = play_area
	_props.view_size = play_area
	DebugCapture.register_provider("Run", _debug_state)
	_level_up_screen.card_chosen.connect(_on_card_chosen)
	_defeat_screen.restart_requested.connect(_restart)
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
	# While the cards are up the Run is paused: the view stops calling step
	# (ADR-0001) and drops the time, so the run doesn't lurch to catch up
	# when the pick is made.
	if _snapshot.phase == Run.Phase.LEVEL_UP:
		_accumulator = 0.0
		# No frame time for the animations either: the crowd stands frozen
		# behind the cards.
		_render(0.0)
		return
	_accumulator += delta
	var steps: int = 0
	while _accumulator >= Run.TIMESTEP and steps < MAX_STEPS_PER_FRAME:
		_previous = _snapshot
		var events: Array[RunEvent] = _run.step(Run.TIMESTEP, _read_move_direction())
		_snapshot = _run.snapshot()
		_accumulator -= Run.TIMESTEP
		steps += 1
		# Ending the run or putting cards up empties the accumulator, which
		# ends this loop.
		_react_to(events)
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
	_pickups.show_pickups(_snapshot, _previous, blend)
	_sand.follow(shown)
	_props.follow(shown)
	_timer_label.text = format_run_time(_snapshot.time)
	_patience_bar.show_amount(_snapshot.patience, _snapshot.max_patience)
	_level_bar.show_amount(_snapshot.level_cash, _snapshot.level_cash_needed)
	_level_label.text = "Lv %d" % _snapshot.level


## Shows the screens the Run's events call for.
func _react_to(events: Array[RunEvent]) -> void:
	for event: RunEvent in events:
		if event is RunEndedEvent:
			_on_run_ended()
		elif event is CardsOfferedEvent:
			_on_cards_offered()


## The Run has paused on level-up cards: show them. Everything else stays
## on screen behind the cards, frozen on the step that leveled up.
func _on_cards_offered() -> void:
	_accumulator = 0.0
	_previous = _snapshot
	_level_up_screen.show_cards(_snapshot, _weapon_name)


## Enter on a card: the Run applies it and either goes on playing or puts up
## the cards for the next level-up waiting behind this one.
func _on_card_chosen(index: int) -> void:
	var events: Array[RunEvent] = _run.choose_card(index)
	_snapshot = _run.snapshot()
	_previous = _snapshot
	_level_up_screen.hide_cards()
	_react_to(events)
	_render(0.0)


## The run is over. Called from inside _process, so this frame still draws
## the final state before everything stops.
func _on_run_ended() -> void:
	# Nothing moves any more: no steps left to take, and nothing to blend
	# towards, so this frame draws exactly the final state.
	_accumulator = 0.0
	_previous = _snapshot
	# The Run ignores further steps; stopping _process also stops the walk
	# animations, so the crowd stands frozen behind the end screen.
	set_process(false)
	# An automatic debug capture of the moment it ended (design, "Debug
	# captures"). Its state.txt is written now, from the final snapshot.
	DebugCapture.capture("run ended")
	# The capture's screenshot is the frame being drawn right now. Show the
	# screen one frame later, so the picture is of the crowd that got her
	# and not of the screen covering it.
	await get_tree().process_frame
	_defeat_screen.show_defeat(_snapshot)


## Enter on the end screen: start over with a fresh Run. Reloading the scene
## builds a new RunView, which picks a new seed. (From ticket 09 this goes to
## weapon select instead.)
func _restart() -> void:
	get_tree().reload_current_scene()


## Broken content stops the game with a message saying what to fix, instead
## of a crash somewhere deep inside the Run.
func _stop_with_content_errors(content: ContentRegistry) -> void:
	push_error(content.error_report())
	_error_label.text = content.error_report()
	_error_label.visible = true
	_timer_label.visible = false
	_patience_bar.visible = false
	_level_bar.visible = false
	_level_label.visible = false
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
