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

## Behavior ID -> behavior class, for admirers. An admirer type's data names
## its behavior by one of these IDs. A new behavior class goes here.
## (preload, not the class name, because a constant must be known when the
## script compiles.)
const ADMIRER_BEHAVIORS: Dictionary = {
	&"chase": preload("res://src/run/admirers/chase_behavior.gd"),
}

## Sensible ranges. Outside them a number is almost certainly a typo, and the
## game would be broken or unplayable, so startup rejects it.
const MIN_MOVE_SPEED: float = 10.0
const MAX_MOVE_SPEED: float = 400.0
const MIN_BODY_RADIUS: float = 2.0
const MAX_BODY_RADIUS: float = 32.0

## Shireen's data. Null if her data file could not be loaded.
var shireen: ShireenData

## Admirer types by id. Only types whose files loaded are here.
var admirers: Dictionary[StringName, AdmirerData] = {}

## How fast admirers arrive. Null means none arrive, which only purpose-built
## test content does; the real game always has a spawn file.
var spawn_ramp: SpawnRampData

## One readable message per problem found, empty if the content is valid.
var errors: PackedStringArray = PackedStringArray()


## Loads the real game content.
static func load_default() -> ContentRegistry:
	return load_from(SHIREEN_PATH, ADMIRERS_DIR, SPAWN_RAMP_PATH)


## Loads content from the given data files and validates it. Tests pass a
## broken file for one part and the real files for the rest.
static func load_from(shireen_path: String, admirers_dir: String = ADMIRERS_DIR, spawn_ramp_path: String = SPAWN_RAMP_PATH) -> ContentRegistry:
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
	registry._add_admirers(admirer_types)
	registry._validate()
	return registry


## Wraps data that is already in memory and validates it. Tests use this to
## build small, purpose-built content sets. With no spawn ramp, no admirers
## ever arrive.
static func from_data(p_shireen: ShireenData, p_admirers: Array[AdmirerData] = [], p_spawn_ramp: SpawnRampData = null) -> ContentRegistry:
	var registry := ContentRegistry.new()
	registry.shireen = p_shireen
	registry.spawn_ramp = p_spawn_ramp
	registry._add_admirers(p_admirers)
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


## A name for a resource with no id yet: its file, or "(unsaved)".
static func _describe(resource: Resource) -> String:
	return resource.resource_path.get_file() if resource.resource_path != "" else "(unsaved)"


# --- Validation -------------------------------------------------------------

func _validate() -> void:
	if shireen != null:
		_check_range("Shireen", "move_speed", shireen.move_speed, MIN_MOVE_SPEED, MAX_MOVE_SPEED, " px/s")
		_check_range("Shireen", "max_patience", shireen.max_patience, 1.0, 10000.0, "")
		_check_range("Shireen", "body_radius", shireen.body_radius, MIN_BODY_RADIUS, MAX_BODY_RADIUS, " px")

	for admirer: AdmirerData in admirers.values():
		var label: String = "Admirer %s" % admirer.id
		if not ADMIRER_BEHAVIORS.has(admirer.behavior_id):
			errors.append("%s: behavior_id \"%s\" is not a known behavior. Known behaviors: %s." % [
				label, admirer.behavior_id, ", ".join(_known_behaviors()),
			])
		_check_range(label, "max_hp", admirer.max_hp, 1.0, 10000.0, "")
		_check_range(label, "move_speed", admirer.move_speed, MIN_MOVE_SPEED, MAX_MOVE_SPEED, " px/s")
		_check_range(label, "drain_per_second", admirer.drain_per_second, 0.0, 100.0, "")
		_check_range(label, "cash", admirer.cash, 0, 100, "")
		_check_range(label, "body_radius", admirer.body_radius, MIN_BODY_RADIUS, MAX_BODY_RADIUS, " px")

	if spawn_ramp != null:
		if not admirers.has(spawn_ramp.admirer_id):
			errors.append("Spawn ramp: admirer_id \"%s\" is not an admirer type. Known types: %s." % [
				spawn_ramp.admirer_id, ", ".join(_known_admirers()),
			])
		_check_range("Spawn ramp", "spawns_per_second_at_start", spawn_ramp.spawns_per_second_at_start, 0.0, 100.0, "")
		_check_range("Spawn ramp", "extra_spawns_per_second_each_minute", spawn_ramp.extra_spawns_per_second_each_minute, 0.0, 100.0, "")
		_check_range("Spawn ramp", "max_admirers", spawn_ramp.max_admirers, 1, 1000, "")
		_check_range("Spawn ramp", "spawn_margin", spawn_ramp.spawn_margin, 0.0, 200.0, " px")


## Records "<label>: <field> must be between A and B<unit>, but it is V."
## when [param value] is outside the range.
func _check_range(label: String, field: String, value: float, low: float, high: float, unit: String) -> void:
	if value < low or value > high:
		errors.append("%s: %s must be between %s and %s%s, but it is %s." % [
			label, field, _format_number(low), _format_number(high), unit, _format_number(value),
		])


func _known_behaviors() -> PackedStringArray:
	var names := PackedStringArray()
	for id: StringName in ADMIRER_BEHAVIORS.keys():
		names.append(id)
	names.sort()
	return names


func _known_admirers() -> PackedStringArray:
	var names := PackedStringArray()
	for id: StringName in admirers.keys():
		names.append(id)
	names.sort()
	return names if not names.is_empty() else PackedStringArray(["(none)"])


## 90.0 -> "90", 90.5 -> "90.5": messages read like the inspector, not code.
static func _format_number(value: float) -> String:
	return str(int(value)) if value == floorf(value) else str(value)
