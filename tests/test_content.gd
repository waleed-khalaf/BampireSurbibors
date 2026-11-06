class_name TestContent
extends RefCounted
## Content sets for tests. The Run never loads files itself (ADR-0001), so
## every test hands it content built here.


## The real game content, loaded from content/.
static func real() -> ContentRegistry:
	return ContentRegistry.load_default()


## The real Dowry Uncle data, loaded from content/admirers/.
static func real_uncle() -> AdmirerData:
	return real().admirers[&"dowry_uncle"]


## Shireen's data with a chosen speed. Round numbers make expected distances
## easy to read in a test.
static func shireen_with_speed(move_speed: float) -> ShireenData:
	var shireen := ShireenData.new()
	shireen.move_speed = move_speed
	return shireen


## A content set whose only difference from the defaults is Shireen's speed.
## No admirers arrive, so tests about walking aren't disturbed.
static func with_shireen_speed(move_speed: float) -> ContentRegistry:
	return ContentRegistry.from_data(shireen_with_speed(move_speed))


## A spawn ramp for [param admirer_id] with a steady rate (no ramp) and a cap.
static func steady_spawns(admirer_id: StringName, per_second: float, max_admirers: int) -> SpawnRampData:
	var spawns := SpawnRampData.new()
	spawns.admirer_id = admirer_id
	spawns.spawns_per_second_at_start = per_second
	spawns.extra_spawns_per_second_each_minute = 0.0
	spawns.max_admirers = max_admirers
	return spawns


## The real Shireen and Dowry Uncle, with [param count] Uncles arriving as
## fast as the content allows (100 per second, so the first on step 1) and
## no more after that.
static func uncle_crowd(count: int) -> ContentRegistry:
	var content := real()
	return ContentRegistry.from_data(content.shireen, [real_uncle()], steady_spawns(&"dowry_uncle", 100.0, count))


## The real Shireen and Dowry Uncle, with Uncles arriving at a steady rate.
static func steady_uncles(per_second: float, max_admirers: int = 1000) -> ContentRegistry:
	var content := real()
	return ContentRegistry.from_data(content.shireen, [real_uncle()], steady_spawns(&"dowry_uncle", per_second, max_admirers))
