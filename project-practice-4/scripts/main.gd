extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var record_button: Button = $UI/Controls/RecordButton
@onready var replay_button: Button = $UI/Controls/ReplayButton
@onready var status_label: Label = $UI/Controls/StatusLabel

func _ready() -> void:
	record_button.pressed.connect(_on_record_button_pressed)
	replay_button.pressed.connect(_on_replay_button_pressed)
	player.replay_finished.connect(_on_replay_finished)
	_update_controls()

func _process(_delta: float) -> void:
	_update_controls()

func _on_record_button_pressed() -> void:
	if player.is_recording_commands:
		player.stop_recording()
	else:
		player.start_recording()
	_update_controls()

func _on_replay_button_pressed() -> void:
	if player.is_recording_commands:
		player.stop_recording()
	player.replay_commands()
	_update_controls()

func _on_replay_finished() -> void:
	_update_controls()

func _update_controls() -> void:
	if player.is_replaying_commands:
		record_button.disabled = true
		record_button.text = "Recording Disabled"
		status_label.text = "Replaying actions..."
	elif player.is_recording_commands:
		record_button.disabled = false
		record_button.text = "Stop Recording"
		status_label.text = "Recording actions..."
	else:
		record_button.disabled = false
		record_button.text = "Record Actions"
		status_label.text = _get_history_status()
	replay_button.disabled = player.command_history.is_empty() or player.is_replaying_commands

func _get_history_status() -> String:
	if player.command_history.is_empty():
		return "Actions stored: 0"
	var last_action: RecordedCommand = player.command_history.back()
	return "Actions stored: %d\nLast action: %.2fs" % [player.command_history.size(), last_action.timestamp]