class_name ContentRegistry
extends RefCounted
## Loads and validates all content data (see the glossary). A Run is built
## from one of these, so the Run itself never loads files.
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

## Sensible range for Shireen's speed. Outside it she is stuck or uncatchable.
const MIN_MOVE_SPEED: float = 10.0
const MAX_MOVE_SPEED: float = 400.0

## Shireen's data. Null if her data file could not be loaded.
var shireen: ShireenData

## One readable message per problem found, empty if the content is valid.
var errors: PackedStringArray = PackedStringArray()


## Loads the real game content.
static func load_default() -> ContentRegistry:
	return load_from(SHIREEN_PATH)


## Loads content from the given data files and validates it.
static func load_from(shireen_path: String) -> ContentRegistry:
	var registry := ContentRegistry.new()
	if not ResourceLoader.exists(shireen_path):
		registry.errors.append("Shireen: no data file at %s." % shireen_path)
		return registry
	var resource: Resource = load(shireen_path)
	if not resource is ShireenData:
		registry.errors.append("Shireen: %s is a %s, not ShireenData. Its script should be %s." % [
			shireen_path, resource.get_class(), (ShireenData as Script).resource_path,
		])
		return registry
	registry.shireen = resource
	registry._validate()
	return registry


## Wraps data that is already in memory and validates it. Tests use this to
## build small, purpose-built content sets.
static func from_data(p_shireen: ShireenData) -> ContentRegistry:
	var registry := ContentRegistry.new()
	registry.shireen = p_shireen
	registry._validate()
	return registry


func is_valid() -> bool:
	return errors.is_empty()


## All errors as one block of text, for the error screen and the log.
func error_report() -> String:
	return "The game content has %d problem(s):\n- %s" % [errors.size(), "\n- ".join(errors)]


func _validate() -> void:
	var speed: float = shireen.move_speed
	if speed < MIN_MOVE_SPEED or speed > MAX_MOVE_SPEED:
		errors.append("Shireen: move_speed must be between %s and %s px/s, but it is %s." % [
			_format_number(MIN_MOVE_SPEED), _format_number(MAX_MOVE_SPEED), _format_number(speed),
		])


## 90.0 -> "90", 90.5 -> "90.5": messages read like the inspector, not code.
static func _format_number(value: float) -> String:
	return str(int(value)) if value == floorf(value) else str(value)
