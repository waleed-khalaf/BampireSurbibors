class_name CaptureFiles
extends RefCounted
## File naming and clean-up for debug captures. Kept apart from the capture
## service so the rules can be tested without a window.


## A date-and-time name that sorts in time order, e.g. "2026-11-06_14-03-22".
## [param datetime] is a dictionary like Time.get_datetime_dict_from_system().
static func timestamp_name(datetime: Dictionary) -> String:
	return "%04d-%02d-%02d_%02d-%02d-%02d" % [
		datetime.year, datetime.month, datetime.day,
		datetime.hour, datetime.minute, datetime.second,
	]


## Turns a capture reason into something safe for a file name:
## "Run ended!" -> "run-ended".
static func slug(reason: String) -> String:
	var result: String = ""
	for character: String in reason.to_lower():
		var code: int = character.unicode_at(0)
		var is_letter: bool = code >= 97 and code <= 122
		var is_digit: bool = code >= 48 and code <= 57
		if is_letter or is_digit:
			result += character
		elif not result.ends_with("-"):
			result += "-"
	result = result.trim_prefix("-").trim_suffix("-")
	return result if not result.is_empty() else "capture"


## [param path] if nothing exists there yet, otherwise the same path with
## "_2", "_3" and so on added, so two captures in the same second both stay.
static func unused_path(path: String) -> String:
	if not FileAccess.file_exists(path) and not DirAccess.dir_exists_absolute(path):
		return path
	var extension: String = path.get_extension()
	var stem: String = path.get_basename() if not extension.is_empty() else path
	var number: int = 2
	while true:
		var candidate: String = "%s_%d" % [stem, number]
		if not extension.is_empty():
			candidate += "." + extension
		if not FileAccess.file_exists(candidate) and not DirAccess.dir_exists_absolute(candidate):
			return candidate
		number += 1
	return path


## Deletes the oldest files with [param extension] in [param folder] until
## only [param keep] are left. File names are timestamps, so sorting by name
## sorts by age. Returns how many files were deleted.
static func keep_newest(folder: String, extension: String, keep: int) -> int:
	var names: Array[String] = []
	for file_name: String in DirAccess.get_files_at(folder):
		if file_name.get_extension() == extension:
			names.append(file_name)
	names.sort()
	var deleted: int = 0
	while names.size() > keep:
		DirAccess.remove_absolute(folder.path_join(names.pop_front()))
		deleted += 1
	return deleted
