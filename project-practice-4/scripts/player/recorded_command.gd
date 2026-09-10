class_name RecordedCommand
extends RefCounted

var command: PlayerCommand
var timestamp: float

func _init(recorded_command: PlayerCommand, recorded_timestamp: float) -> void:
	command = recorded_command
	timestamp = recorded_timestamp