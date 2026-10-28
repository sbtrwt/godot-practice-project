extends Node
## Versioned JSON persistence for local settings and progression.

const SAVE_PATH: String = "user://mini_militia_clone_save.json"
const TEMP_SAVE_PATH: String = "user://mini_militia_clone_save.tmp"
const SAVE_VERSION: int = 2


## Saves JSON-compatible local data atomically enough for the prototype.
func save_game(data: Dictionary) -> Error:
	var payload: Dictionary = {"version": SAVE_VERSION, "data": _normalize_data(data)}
	var file := FileAccess.open(TEMP_SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(payload))
	file.close()
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	return DirAccess.rename_absolute(
		ProjectSettings.globalize_path(TEMP_SAVE_PATH),
		ProjectSettings.globalize_path(SAVE_PATH)
	)


## Loads data or returns an empty dictionary when no compatible save exists.
func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if parsed is Dictionary:
		@warning_ignore("unsafe_cast")
		var payload: Dictionary = parsed as Dictionary
		var migrated: Dictionary = migrate_payload(payload)
		if not migrated.is_empty():
			return migrated
	return {}


## Converts supported historical payloads into the current save schema.
func migrate_payload(payload: Dictionary) -> Dictionary:
	var version := int(payload.get("version", -1))
	var data: Variant = payload.get("data", {})
	if not data is Dictionary:
		return {}
	@warning_ignore("unsafe_cast")
	var migrated: Dictionary = (data as Dictionary).duplicate(true)
	if version == 1:
		migrated = _migrate_v1_to_v2(migrated)
		version = 2
	if version != SAVE_VERSION:
		return {}
	return _normalize_data(migrated)


func _migrate_v1_to_v2(data: Dictionary) -> Dictionary:
	var migrated := data.duplicate(true)
	if not migrated.has("settings"):
		migrated["settings"] = {"control_scheme": "twin_stick"}
	if not migrated.has("profile"):
		migrated["profile"] = {"display_name": "Player"}
	return migrated


func _normalize_data(data: Dictionary) -> Dictionary:
	var normalized := data.duplicate(true)
	if not normalized.has("settings"):
		normalized["settings"] = {"control_scheme": "twin_stick"}
	if not normalized.has("profile"):
		normalized["profile"] = {"display_name": "Player"}
	return normalized
