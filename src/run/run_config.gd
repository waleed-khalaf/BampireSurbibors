class_name RunConfig
extends RefCounted
## Everything a Run needs to start. Two Runs built from equal configs and fed
## the same inputs must end up in the same state (see ADR-0001).
##
## Later tickets add the chosen weapon ID here.

## Seed for the Run's own RNG. All randomness in a Run comes from this.
var rng_seed: int = 0

## The 640×360 base resolution, for callers that have no engine to ask (tests).
## The game itself passes the size it reads from the project settings.
const DEFAULT_PLAY_AREA: Vector2 = Vector2(640, 360)

## Size of the visible play area in pixels.
## The Run uses it to place spawns just off-screen; it never asks the engine.
var play_area: Vector2 = DEFAULT_PLAY_AREA

## The content set the Run plays with: Shireen's data for now, later the
## weapons, admirers and the rest.
var content: ContentRegistry


## [param p_content] defaults to the real game content, so a test that doesn't
## care about content can just write RunConfig.new(seed).
func _init(p_seed: int = 0, p_play_area: Vector2 = DEFAULT_PLAY_AREA, p_content: ContentRegistry = null) -> void:
	rng_seed = p_seed
	play_area = p_play_area
	content = p_content if p_content != null else ContentRegistry.load_default()
