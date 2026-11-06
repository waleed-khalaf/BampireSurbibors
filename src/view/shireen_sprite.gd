class_name ShireenSprite
extends Sprite2D
## Draws Shireen from the Run's snapshot: picks the idle or walk animation
## from whether she is moving, and mirrors her to face left or right.
##
## The sheet is res://art/shireen/shireen.png, one row of 32×32 frames:
## 0–1 idle shimmy, 2–5 walk (see art/README.md).

const IDLE_FRAMES: Array[int] = [0, 1]
const IDLE_FPS: float = 3.0
const WALK_FRAMES: Array[int] = [2, 3, 4, 5]
const WALK_FPS: float = 8.0

var _moving: bool = false
## Seconds spent in the current animation, so each one starts on frame 0.
var _anim_time: float = 0.0


## Shows Shireen's state from one snapshot. [param delta] is the real frame
## time, which only drives the animation speed.
func show_state(snapshot: RunSnapshot, delta: float) -> void:
	if snapshot.shireen_moving != _moving:
		_moving = snapshot.shireen_moving
		_anim_time = 0.0
	else:
		_anim_time += delta

	var frames: Array[int] = WALK_FRAMES if _moving else IDLE_FRAMES
	var fps: float = WALK_FPS if _moving else IDLE_FPS
	frame = frames[floori(_anim_time * fps) % frames.size()]

	# The art faces right. Walking straight up or down keeps the last flip,
	# because her facing then has no left/right part.
	if snapshot.shireen_facing.x < -0.01:
		flip_h = true
	elif snapshot.shireen_facing.x > 0.01:
		flip_h = false
