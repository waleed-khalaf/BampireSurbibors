class_name TestContent
extends RefCounted
## Content sets for tests. The Run never loads files itself (ADR-0001), so
## every test hands it content built here.


## The real game content, loaded from content/.
static func real() -> ContentRegistry:
	return ContentRegistry.load_default()


## Shireen's data with a chosen speed. Round numbers make expected distances
## easy to read in a test.
static func shireen_with_speed(move_speed: float) -> ShireenData:
	var shireen := ShireenData.new()
	shireen.move_speed = move_speed
	return shireen


## A content set whose only difference from the defaults is Shireen's speed.
static func with_shireen_speed(move_speed: float) -> ContentRegistry:
	return ContentRegistry.from_data(shireen_with_speed(move_speed))
