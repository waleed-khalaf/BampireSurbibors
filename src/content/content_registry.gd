class_name ContentRegistry
extends RefCounted
## Loads and validates all content data and maps behavior IDs to behavior
## classes (see the glossary). A Run is built from one of these, so the Run
## itself never loads files.
##
## Loading never stops at the first problem: it collects every error it finds
## in [member errors], so one start of the game reports all broken content at
## once. Check [method is_valid] before building a Run.
##
## Usage:
##     var content := ContentRegistry.load_default()
##     if not content.is_valid():
##         push_error(content.error_report())

## Where the real game content lives.
const SHIREEN_PATH: String = "res://content/shireen.tres"
## Every .tres file in this folder is one admirer type.
const ADMIRERS_DIR: String = "res://content/admirers"
const SPAWN_RAMP_PATH: String = "res://content/spawn_ramp.tres"
## Every .tres file in this folder is one weapon.
const WEAPONS_DIR: String = "res://content/weapons"
const LEVELING_PATH: String = "res://content/leveling.tres"
const PICKUPS_PATH: String = "res://content/pickups.tres"

## Behavior ID -> behavior class, for admirers. An admirer type's data names
## its behavior by one of these IDs. A new behavior class goes here.
## (preload, not the class name, because a constant must be known when the
## script compiles.)
const ADMIRER_BEHAVIORS: Dictionary = {
	&"chase": preload("res://src/run/admirers/chase_behavior.gd"),
}

## Behavior ID -> behavior class, for weapons. A weapon's data names its
## behavior by one of these IDs. A new weapon's behavior class goes here.
const WEAPON_BEHAVIORS: Dictionary = {
	&"zills": preload("res://src/run/weapons/zills_behavior.gd"),
}

## Behavior ID -> behavior class, for abilities. Empty until the first
## abilities arrive (ticket 12); see AbilityBehavior.
const ABILITY_BEHAVIORS: Dictionary = {}

## Sensible ranges. Outside them a number is almost certainly a typo, and the
## game would be broken or unplayable, so startup rejects it.
const MIN_MOVE_SPEED: float = 10.0
const MAX_MOVE_SPEED: float = 400.0
const MIN_BODY_RADIUS: float = 2.0
const MAX_BODY_RADIUS: float = 32.0

## Every weapon has this many buff tracks, and a track at most this many
## ranks (design §5).
const BUFF_TRACKS_PER_WEAPON: int = 4
const MAX_BUFF_RANK: int = 5

## Shireen's data. Null if her data file could not be loaded.
var shireen: ShireenData

## Admirer types by id. Only types whose files loaded are here.
var admirers: Dictionary[StringName, AdmirerData] = {}

## How fast admirers arrive. Null means none arrive, which only purpose-built
## test content does; the real game always has a spawn file.
var spawn_ramp: SpawnRampData

## Weapons by id. Only weapons whose files loaded are here. Purpose-built
## test content may have none; a Run needs one only if its config picks one.
var weapons: Dictionary[StringName, WeaponData] = {}

## The leveling curve. Null only if its file could not be loaded.
var leveling: LevelingData

## How cash flies and karkadeh tea drops. Null only if its file could not be
## loaded.
var pickups: PickupData

## One readable message per problem found, empty if the content is valid.
var errors: PackedStringArray = PackedStringArray()


## Loads the real game content.
static func load_default() -> ContentRegistry:
	return load_from(SHIREEN_PATH, ADMIRERS_DIR, SPAWN_RAMP_PATH, WEAPONS_DIR, LEVELING_PATH, PICKUPS_PATH)


## Loads content from the given data files and validates it. Tests pass a
## broken file for one part and the real files for the rest.
static func load_from(shireen_path: String, admirers_dir: String = ADMIRERS_DIR, spawn_ramp_path: String = SPAWN_RAMP_PATH, weapons_dir: String = WEAPONS_DIR, leveling_path: String = LEVELING_PATH, pickups_path: String = PICKUPS_PATH) -> ContentRegistry:
	var registry := ContentRegistry.new()
	registry.shireen = registry._load_file(shireen_path, "Shireen", ShireenData)

	var admirer_paths: PackedStringArray = registry._list_data_files(admirers_dir)
	if admirer_paths.is_empty():
		registry.errors.append("Admirers: no admirer data files in %s." % admirers_dir)
	var admirer_types: Array[AdmirerData] = []
	for path: String in admirer_paths:
		var admirer: AdmirerData = registry._load_file(path, "Admirer file %s" % path.get_file(), AdmirerData)
		if admirer != null:
			admirer_types.append(admirer)

	registry.spawn_ramp = registry._load_file(spawn_ramp_path, "Spawn ramp", SpawnRampData)

	var weapon_paths: PackedStringArray = registry._list_data_files(weapons_dir)
	if weapon_paths.is_empty():
		registry.errors.append("Weapons: no weapon data files in %s." % weapons_dir)
	var weapon_list: Array[WeaponData] = []
	for path: String in weapon_paths:
		var weapon: WeaponData = registry._load_file(path, "Weapon file %s" % path.get_file(), WeaponData)
		if weapon != null:
			weapon_list.append(weapon)

	registry.leveling = registry._load_file(leveling_path, "Leveling", LevelingData)
	registry.pickups = registry._load_file(pickups_path, "Pickups", PickupData)

	registry._add_admirers(admirer_types)
	registry._add_weapons(weapon_list)
	registry._validate()
	return registry


## Wraps data that is already in memory and validates it. Tests use this to
## build small, purpose-built content sets. With no spawn ramp, no admirers
## ever arrive; with no weapons, Shireen can't be given one. Leveling and
## pickup data left out fall back to the defaults in their classes, which are
## the design's numbers.
static func from_data(p_shireen: ShireenData, p_admirers: Array[AdmirerData] = [], p_spawn_ramp: SpawnRampData = null, p_weapons: Array[WeaponData] = [], p_leveling: LevelingData = null, p_pickups: PickupData = null) -> ContentRegistry:
	var registry := ContentRegistry.new()
	registry.shireen = p_shireen
	registry.spawn_ramp = p_spawn_ramp
	registry.leveling = p_leveling if p_leveling != null else LevelingData.new()
	registry.pickups = p_pickups if p_pickups != null else PickupData.new()
	registry._add_admirers(p_admirers)
	registry._add_weapons(p_weapons)
	registry._validate()
	return registry


func is_valid() -> bool:
	return errors.is_empty()


## All errors as one block of text, for the error screen and the log.
func error_report() -> String:
	return "The game content has %d problem(s):\n- %s" % [errors.size(), "\n- ".join(errors)]


## A new behavior object for an admirer type. Only call this on valid
## content, where every behavior ID is known.
func create_admirer_behavior(admirer: AdmirerData) -> AdmirerBehavior:
	var behavior_class: GDScript = ADMIRER_BEHAVIORS[admirer.behavior_id]
	return behavior_class.new()


## A new behavior object for a weapon: one per Run, since it keeps the
## weapon's state. Only call this on valid content.
func create_weapon_behavior(weapon: WeaponData) -> WeaponBehavior:
	var behavior_class: GDScript = WEAPON_BEHAVIORS[weapon.behavior_id]
	return behavior_class.new(weapon)


## A new behavior object for an ability, to hand to
## WeaponBehavior.gain_ability. Only call this on valid content.
func create_ability_behavior(ability: AbilityData) -> AbilityBehavior:
	var behavior_class: GDScript = ABILITY_BEHAVIORS[ability.behavior_id]
	return behavior_class.new()


## The largest body radius among all admirer types, or 0 with none.
func max_admirer_radius() -> float:
	var largest: float = 0.0
	for admirer: AdmirerData in admirers.values():
		largest = maxf(largest, admirer.body_radius)
	return largest


# --- Loading ----------------------------------------------------------------

## Loads one data file and checks it holds the expected type. Returns null and
## records an error if not. [param label] starts each message.
func _load_file(path: String, label: String, type: GDScript) -> Resource:
	if not ResourceLoader.exists(path):
		errors.append("%s: no data file at %s." % [label, path])
		return null
	var resource: Resource = load(path)
	if resource == null:
		errors.append("%s: %s could not be read. Open it in Godot to see what is wrong with it." % [label, path])
		return null
	if not is_instance_of(resource, type):
		errors.append("%s: %s is a %s, not %s. Its script should be %s." % [
			label, path, resource.get_class(), type.get_global_name(), type.resource_path,
		])
		return null
	return resource


## The data files in a folder, sorted so loading order (and so every run) is
## the same on every machine. ResourceLoader.list_directory also finds files
## in exported builds, where plain directory listing sees renamed files.
func _list_data_files(dir: String) -> PackedStringArray:
	var paths := PackedStringArray()
	for file: String in ResourceLoader.list_directory(dir):
		if file.ends_with(".tres") or file.ends_with(".res"):
			paths.append(dir.path_join(file))
	paths.sort()
	return paths


func _add_admirers(admirer_types: Array[AdmirerData]) -> void:
	for admirer: AdmirerData in admirer_types:
		if admirer.id == &"":
			errors.append("Admirer %s: id is empty. Give it a unique id like \"dowry_uncle\"." % _describe(admirer))
			continue
		if admirers.has(admirer.id):
			errors.append("Admirer %s: the id is used by more than one admirer type. Each needs its own." % admirer.id)
			continue
		admirers[admirer.id] = admirer


func _add_weapons(weapon_list: Array[WeaponData]) -> void:
	for weapon: WeaponData in weapon_list:
		if weapon.id == &"":
			errors.append("Weapon %s: id is empty. Give it a unique id like \"zills\"." % _describe(weapon))
			continue
		if weapons.has(weapon.id):
			errors.append("Weapon %s: the id is used by more than one weapon. Each needs its own." % weapon.id)
			continue
		weapons[weapon.id] = weapon


## A name for a resource with no id yet: its file, or "(unsaved)".
static func _describe(resource: Resource) -> String:
	return resource.resource_path.get_file() if resource.resource_path != "" else "(unsaved)"


# --- Validation -------------------------------------------------------------

func _validate() -> void:
	if shireen != null:
		_check_range("Shireen", "move_speed", shireen.move_speed, MIN_MOVE_SPEED, MAX_MOVE_SPEED, " px/s")
		_check_range("Shireen", "max_patience", shireen.max_patience, 1.0, 10000.0, "")
		_check_range("Shireen", "body_radius", shireen.body_radius, MIN_BODY_RADIUS, MAX_BODY_RADIUS, " px")
		_check_range("Shireen", "pickup_radius", shireen.pickup_radius, 1.0, 200.0, " px")

	for admirer: AdmirerData in admirers.values():
		var label: String = "Admirer %s" % admirer.id
		if not ADMIRER_BEHAVIORS.has(admirer.behavior_id):
			errors.append("%s: behavior_id \"%s\" is not a known behavior. Known behaviors: %s." % [
				label, admirer.behavior_id, _name_list(ADMIRER_BEHAVIORS.keys()),
			])
		_check_range(label, "max_hp", admirer.max_hp, 1.0, 10000.0, "")
		_check_range(label, "move_speed", admirer.move_speed, MIN_MOVE_SPEED, MAX_MOVE_SPEED, " px/s")
		_check_range(label, "drain_per_second", admirer.drain_per_second, 0.0, 100.0, "")
		_check_range(label, "cash", admirer.cash, 0, 100, "")
		_check_range(label, "body_radius", admirer.body_radius, MIN_BODY_RADIUS, MAX_BODY_RADIUS, " px")
		_check_range(label, "swoon_seconds", admirer.swoon_seconds, 0.0, 5.0, " s")
		_check_range(label, "leave_speed", admirer.leave_speed, MIN_MOVE_SPEED, MAX_MOVE_SPEED, " px/s")

	if spawn_ramp != null:
		if not admirers.has(spawn_ramp.admirer_id):
			errors.append("Spawn ramp: admirer_id \"%s\" is not an admirer type. Known types: %s." % [
				spawn_ramp.admirer_id, _name_list(admirers.keys()),
			])
		_check_range("Spawn ramp", "spawns_per_second_at_start", spawn_ramp.spawns_per_second_at_start, 0.0, 100.0, "")
		_check_range("Spawn ramp", "extra_spawns_per_second_each_minute", spawn_ramp.extra_spawns_per_second_each_minute, 0.0, 100.0, "")
		_check_range("Spawn ramp", "max_admirers", spawn_ramp.max_admirers, 1, 1000, "")
		_check_range("Spawn ramp", "spawn_margin", spawn_ramp.spawn_margin, 0.0, 200.0, " px")

	for weapon: WeaponData in weapons.values():
		_validate_weapon(weapon)

	if leveling != null:
		_check_range("Leveling", "cash_for_first_level_up", leveling.cash_for_first_level_up, 1, 1000, "")
		_check_range("Leveling", "extra_cash_each_level", leveling.extra_cash_each_level, 0, 1000, "")
		for level: int in leveling.ability_levels:
			_check_range("Leveling", "ability_levels", level, 2, 100, "")
		_check_range("Leveling", "big_tip_cash", leveling.big_tip_cash, 1, 1000, "")
		_check_range("Leveling", "sip_of_tea_patience", leveling.sip_of_tea_patience, 1.0, 10000.0, "")

	if pickups != null:
		_check_range("Pickups", "cash_fly_speed", pickups.cash_fly_speed, 50.0, 2000.0, " px/s")
		_check_range("Pickups", "tea_drop_chance", pickups.tea_drop_chance, 0.0, 1.0, "")
		_check_range("Pickups", "tea_patience", pickups.tea_patience, 1.0, 10000.0, "")
		_check_range("Pickups", "tea_radius", pickups.tea_radius, 1.0, 32.0, " px")


func _validate_weapon(weapon: WeaponData) -> void:
	var label: String = "Weapon %s" % weapon.id
	# Nothing below can read an empty slot, so those are reported alone.
	if _has_empty_slots(label, weapon):
		return

	if WEAPON_BEHAVIORS.has(weapon.behavior_id):
		# The behavior says which stats it reads and what range each must be
		# in. One missing stat is one message listing them all, so the fix
		# doesn't take a restart per stat.
		var ranges: Dictionary[StringName, Array] = create_weapon_behavior(weapon).stat_ranges()
		for stat: StringName in ranges:
			var low: float = ranges[stat][0]
			var high: float = ranges[stat][1]
			if not weapon.base_stats.has(stat):
				errors.append("%s: base_stats has no \"%s\". Its behavior needs: %s." % [label, stat, _name_list(ranges.keys())])
			elif weapon.base_stats[stat] < low or weapon.base_stats[stat] > high:
				_check_range(label, stat, weapon.base_stats[stat], low, high, "")
			else:
				_check_modified_range(label, weapon, stat, low, high)
	else:
		errors.append("%s: behavior_id \"%s\" is not a known behavior. Known behaviors: %s." % [
			label, weapon.behavior_id, _name_list(WEAPON_BEHAVIORS.keys()),
		])

	if weapon.buff_tracks.size() != BUFF_TRACKS_PER_WEAPON:
		errors.append("%s: it has %d buff tracks, but a weapon needs exactly %d." % [label, weapon.buff_tracks.size(), BUFF_TRACKS_PER_WEAPON])
	var track_ids: Dictionary[StringName, bool] = {}
	for track: BuffTrackData in weapon.buff_tracks:
		var track_label: String = "%s, buff track %s" % [label, track.id]
		if track.id == &"":
			errors.append("%s: a buff track has an empty id. Give it one like \"damage\"." % label)
		elif track_ids.has(track.id):
			errors.append("%s: the id is used by more than one of the weapon's buff tracks. Each needs its own." % track_label)
		track_ids[track.id] = true
		_check_range(track_label, "max_rank", track.max_rank, 1, MAX_BUFF_RANK, "")
		for modifier: StatModifierData in track.modifiers:
			_check_modifier_stat(track_label, modifier, weapon)
			for rank: int in modifier.ranks:
				if rank < 1 or rank > track.max_rank:
					errors.append("%s: a modifier is granted at rank %d, but the track only has ranks 1 to %d." % [track_label, rank, track.max_rank])

	# Ticket 12 brings the abilities and, with them, the rule that a weapon
	# has exactly 5, one of them its weakness fix. Until then a weapon may
	# have none.
	for ability: AbilityData in weapon.abilities:
		var ability_label: String = "%s, ability %s" % [label, ability.id]
		if not ABILITY_BEHAVIORS.has(ability.behavior_id):
			errors.append("%s: behavior_id \"%s\" is not a known ability behavior. Known behaviors: %s." % [
				ability_label, ability.behavior_id, _name_list(ABILITY_BEHAVIORS.keys()),
			])
		for modifier: StatModifierData in ability.modifiers:
			_check_modifier_stat(ability_label, modifier, weapon)
			if not modifier.ranks.is_empty():
				errors.append("%s: a modifier lists ranks, but only buff tracks have ranks. Clear its ranks." % ability_label)


## Records an error for every empty slot in [param weapon]'s lists: what
## the Inspector leaves behind when a slot is added and never filled.
## Returns whether it found any.
func _has_empty_slots(label: String, weapon: WeaponData) -> bool:
	var found: bool = _check_slots(label, "buff track", weapon.buff_tracks)
	for track: BuffTrackData in weapon.buff_tracks:
		if track != null:
			found = _check_slots("%s, buff track %s" % [label, track.id], "modifier", track.modifiers) or found
	found = _check_slots(label, "ability", weapon.abilities) or found
	for ability: AbilityData in weapon.abilities:
		if ability != null:
			found = _check_slots("%s, ability %s" % [label, ability.id], "modifier", ability.modifiers) or found
	return found


## Records "<label>: <what> slot N is empty..." for every empty slot in
## [param slots], counting from 1 as the Inspector's reader would. Returns
## whether it found any.
func _check_slots(label: String, what: String, slots: Array) -> bool:
	var found: bool = false
	for i: int in slots.size():
		if slots[i] == null:
			errors.append("%s: %s slot %d is empty. Fill it, or remove the slot." % [label, what, i + 1])
			found = true
	return found


## Records an error when [param weapon]'s buff tracks and abilities could
## take [param stat] outside [param low] to [param high]: "-1 zill a rank"
## would leave nothing to throw, "-100% cooldown" no pause between attacks.
## It looks at the furthest the stat could go either way, with every track
## at any rank and every ability gained or not.
func _check_modified_range(label: String, weapon: WeaponData, stat: StringName, low: float, high: float) -> void:
	# The most the modifiers can add and take away, indexed by
	# StatModifierData.Kind: plain amounts first, then shares.
	var most: PackedFloat64Array = [0.0, 0.0]
	var least: PackedFloat64Array = [0.0, 0.0]
	for track: BuffTrackData in weapon.buff_tracks:
		for modifier: StatModifierData in track.modifiers:
			if modifier.stat == stat:
				var amount: float = modifier.value * modifier.times_at_rank(track.max_rank)
				most[modifier.kind] += maxf(amount, 0.0)
				least[modifier.kind] += minf(amount, 0.0)
	for ability: AbilityData in weapon.abilities:
		for modifier: StatModifierData in ability.modifiers:
			if modifier.stat == stat:
				most[modifier.kind] += maxf(modifier.value, 0.0)
				least[modifier.kind] += minf(modifier.value, 0.0)

	# The same sum as Stats.value: (base + added) × (1 + shares), where the
	# shares can't take the value below zero.
	var add: int = StatModifierData.Kind.ADD
	var share: int = StatModifierData.Kind.MULTIPLY
	var highest: float = (weapon.base_stats[stat] + most[add]) * (1.0 + most[share])
	var lowest: float = weapon.base_stats[stat] + least[add]
	# A value already below zero only gets lower with a larger share.
	lowest *= maxf(1.0 + least[share], 0.0) if lowest >= 0.0 else 1.0 + most[share]

	if lowest < low:
		errors.append("%s: its buffs and abilities can take %s as low as %s, but it must stay between %s and %s." % [
			label, stat, _format_number(lowest), _format_number(low), _format_number(high),
		])
	if highest > high:
		errors.append("%s: its buffs and abilities can take %s as high as %s, but it must stay between %s and %s." % [
			label, stat, _format_number(highest), _format_number(low), _format_number(high),
		])


## Records an error when [param modifier] changes a stat [param weapon]
## doesn't have: almost certainly a typo, and it would silently do nothing.
func _check_modifier_stat(label: String, modifier: StatModifierData, weapon: WeaponData) -> void:
	if not weapon.base_stats.has(modifier.stat):
		errors.append("%s: a modifier changes \"%s\", which is not one of the weapon's stats (%s)." % [
			label, modifier.stat, _name_list(weapon.base_stats.keys()),
		])


## Records "<label>: <field> must be between A and B<unit>, but it is V."
## when [param value] is outside the range.
func _check_range(label: String, field: String, value: float, low: float, high: float, unit: String) -> void:
	if value < low or value > high:
		errors.append("%s: %s must be between %s and %s%s, but it is %s." % [
			label, field, _format_number(low), _format_number(high), unit, _format_number(value),
		])


## "a, b, c" in alphabetical order, or "(none)", for listing the names a
## message's reader could have meant.
static func _name_list(names: Array) -> String:
	var sorted := PackedStringArray()
	for name: StringName in names:
		sorted.append(name)
	sorted.sort()
	return ", ".join(sorted) if not sorted.is_empty() else "(none)"


## 90.0 -> "90", 90.5 -> "90.5": messages read like the inspector, not code.
static func _format_number(value: float) -> String:
	return str(int(value)) if value == floorf(value) else str(value)
