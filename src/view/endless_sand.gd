class_name EndlessSand
extends Sprite2D
## Endless sand: one sprite, just bigger than the screen, that repeats the
## sand tile and jumps along in whole tiles to stay under the camera. Because
## it only ever moves by whole tiles, the pattern looks fixed to the world.

## Size of the visible area in pixels (the 640×360 base resolution).
var view_size: Vector2 = Vector2(640, 360)


func _ready() -> void:
	centered = false
	region_enabled = true
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED


## Keeps the sand covering the screen around [param camera_position].
func follow(camera_position: Vector2) -> void:
	var tile: Vector2 = texture.get_size()
	# One spare tile on every side, so no edge ever shows while scrolling.
	var tiles: Vector2 = (view_size / tile).ceil() + Vector2(2, 2)
	region_rect = Rect2(Vector2.ZERO, tiles * tile)
	var top_left: Vector2 = camera_position - view_size / 2.0
	position = (top_left / tile).floor() * tile - tile
