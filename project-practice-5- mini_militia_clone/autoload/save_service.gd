extends Node
## Versioned JSON persistence for local settings and progression.

const SAVE_PATH: String = "user://mini_militia_clone_save.json"
const TEMP_SAVE_PATH: String = "user://mini_militia_clone_save.tmp"
const SAVE_VERSION: int = 1


## Saves JSON-compatible local data atomically enough for the prototype.
func save_game(data: Dictionary) -> Error:
	var payload: Dictionary = {"version": SAVE_VERSION, "data": data}
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
		if payload.get("version", -1) != SAVE_VERSION:
			return {}
		var data: Variant = payload.get("data", {})
		if data is Dictionary:
			return data
	return {}
