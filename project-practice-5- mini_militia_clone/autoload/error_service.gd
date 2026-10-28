extends Node
## Centralized in-process error boundary for recovery UI and debug diagnostics.

signal error_recorded(code: StringName, message: String)

const MAX_RECORDS: int = 20
var records: Array[Dictionary] = []


func report(code: StringName, message: String) -> void:
	var record := {
		"code": code,
		"message": message,
		"time_ms": Time.get_ticks_msec(),
	}
	records.append(record)
	while records.size() > MAX_RECORDS:
		records.pop_front()
	error_recorded.emit(code, message)


func latest() -> Dictionary:
	return records.back() if not records.is_empty() else {}


func clear() -> void:
	records.clear()
