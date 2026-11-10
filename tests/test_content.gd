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


## The real Dowry Uncle, except that touching him costs no Patience. For tests
## about how a crowd arrives and moves: they run for a long time with Uncles
## pressed against Shireen, and with real ones the run would end on "You said
## yes." partway through.
static func harmless_uncle() -> AdmirerData:
	return made_up_admirer(&"dowry_uncle", 0.0)


## A made-up admirer type: the real Dowry Uncle's numbers under another id,
## with a chosen drain. For tests that tell admirer types apart.
static func made_up_admirer(id: StringName, drain_per_second: float) -> AdmirerData:
	var type: AdmirerData = real_uncle().duplicate()
	type.id = id
	type.drain_per_second = drain_per_second
	return type


## Shireen's data with a chosen speed. Round numbers make expected distances
## easy to read in a test.
static func shireen_with_speed(move_speed: float) -> ShireenData:
	var shireen := ShireenData.new()
	shireen.move_speed = move_speed
	return shireen


## The real Shireen with a chosen amount of Patience. A big number keeps her in
## the run while a test watches the drain for a long time.
static func shireen_with_patience(max_patience: float) -> ShireenData:
	var shireen: ShireenData = real().shireen.duplicate()
	shireen.max_patience = max_patience
	return shireen


## The real Shireen with a chosen cash pickup radius.
static func shireen_with_pickup_radius(pickup_radius: float) -> ShireenData:
	var shireen: ShireenData = real().shireen.duplicate()
	shireen.pickup_radius = pickup_radius
	return shireen


## A leveling curve of [param cash_for_first_level_up] + [param extra_cash_each_level]
## per level after the first.
static func leveling(cash_for_first_level_up: int, extra_cash_each_level: int) -> LevelingData:
	var curve := LevelingData.new()
	curve.cash_for_first_level_up = cash_for_first_level_up
	curve.extra_cash_each_level = extra_cash_each_level
	return curve


## The real pickup numbers with a chosen karkadeh tea drop chance (0 to 1).
static func pickups(tea_drop_chance: float) -> PickupData:
	var data: PickupData = real().pickups.duplicate()
	data.tea_drop_chance = tea_drop_chance
	return data


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


## [param count] admirers of one type arriving as fast as the content allows
## (100 per second, so the first on step 1). [param count] is the spawn cap:
## no more arrive while that many are chasing. They chase the real Shireen
## unless another one is given.
static func crowd(admirer: AdmirerData, count: int, shireen: ShireenData = real().shireen) -> ContentRegistry:
	return ContentRegistry.from_data(shireen, [admirer], steady_spawns(admirer.id, 100.0, count))


## The real Shireen and Dowry Uncle, with [param count] Uncles arriving at
## once (see [method crowd]).
static func uncle_crowd(count: int) -> ContentRegistry:
	return crowd(real_uncle(), count)


## The real Shireen with [param count] harmless Uncles arriving at once (see
## [method crowd] and [method harmless_uncle]).
static func harmless_uncle_crowd(count: int) -> ContentRegistry:
	return crowd(harmless_uncle(), count)


## The real game content, except that its Uncles are harmless: the real
## Shireen and the real spawn ramp.
static func real_with_harmless_uncles() -> ContentRegistry:
	var content := real()
	return ContentRegistry.from_data(content.shireen, [harmless_uncle()], content.spawn_ramp)


## The real Shireen with harmless Uncles arriving at a steady rate.
static func steady_harmless_uncles(per_second: float, max_admirers: int = 1000) -> ContentRegistry:
	return ContentRegistry.from_data(real().shireen, [harmless_uncle()], steady_spawns(&"dowry_uncle", per_second, max_admirers))


## A chosen Shireen chased by harmless Uncles arriving on a chosen ramp.
static func harmless_uncles_chasing(shireen: ShireenData, per_second: float, extra_per_second_each_minute: float, max_admirers: int) -> ContentRegistry:
	return ContentRegistry.from_data(shireen, [harmless_uncle()], ramping_spawns(&"dowry_uncle", per_second, extra_per_second_each_minute, max_admirers))


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


## A harmless Uncle (see [method harmless_uncle]) with so much HP that no test
## dazzles him: for tests that need someone to keep throwing at.
static func tough_uncle() -> AdmirerData:
	var uncle: AdmirerData = harmless_uncle()
	uncle.max_hp = 10000.0
	return uncle


## [param weapon] against [param count] admirers of one type, who all arrive
## within the first second. [param count] is the spawn cap: another arrives
## only to replace one who was dazzled. They chase the real Shireen unless
## another one is given.
static func weapon_against(weapon: WeaponData, admirer: AdmirerData, count: int, shireen: ShireenData = real().shireen) -> ContentRegistry:
	return ContentRegistry.from_data(shireen, [admirer], steady_spawns(admirer.id, 100.0, count), [weapon])
