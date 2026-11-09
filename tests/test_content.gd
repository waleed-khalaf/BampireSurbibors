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
	return ramping_spawns(admirer_id, per_second, 0.0, max_admirers)


## A spawn ramp for [param admirer_id] that starts at [param per_second] and
## climbs by [param extra_per_second_each_minute], up to a cap.
static func ramping_spawns(admirer_id: StringName, per_second: float, extra_per_second_each_minute: float, max_admirers: int) -> SpawnRampData:
	var spawns := SpawnRampData.new()
	spawns.admirer_id = admirer_id
	spawns.spawns_per_second_at_start = per_second
	spawns.extra_spawns_per_second_each_minute = extra_per_second_each_minute
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


## A chosen Shireen chased by real Dowry Uncles arriving on a chosen ramp.
static func uncles_chasing(shireen: ShireenData, per_second: float, extra_per_second_each_minute: float, max_admirers: int) -> ContentRegistry:
	return ContentRegistry.from_data(shireen, [real_uncle()], ramping_spawns(&"dowry_uncle", per_second, extra_per_second_each_minute, max_admirers))


# --- Weapons ----------------------------------------------------------------

## The real Zills data, loaded from content/weapons/.
static func real_zills() -> WeaponData:
	return real().weapons[&"zills"]


## The real Zills with some base stats replaced, e.g. {&"pierce": 2.0}. The
## weapon keeps the id "zills".
static func zills_with(base_stats: Dictionary[StringName, float]) -> WeaponData:
	var zills: WeaponData = real_zills().duplicate(true)
	for stat: StringName in base_stats:
		zills.base_stats[stat] = base_stats[stat]
	return zills


## The real Dowry Uncle, but with so much HP that no test dazzles him: for
## tests that need someone to keep throwing at.
static func tough_uncle() -> AdmirerData:
	var uncle: AdmirerData = real_uncle().duplicate()
	uncle.max_hp = 10000.0
	return uncle


## The real Shireen with [param weapon] against [param count] admirers of
## one type, who all arrive within the first second and no more after that.
static func weapon_against(weapon: WeaponData, admirer: AdmirerData, count: int) -> ContentRegistry:
	return ContentRegistry.from_data(real().shireen, [admirer], steady_spawns(admirer.id, 100.0, count), [weapon])
