extends Control
## Presentation-only match HUD. It reads service state and never owns gameplay rules.

@onready var _state_label: Label = $State
@onready var _timer_label: Label = $Timer
@onready var _score_label: Label = $Score


func _ready() -> void:
	MatchService.match_state_changed.connect(_on_match_state_changed)
	MatchService.score_changed.connect(_on_score_changed)
	_on_match_state_changed(&"lobby")


func _process(_delta: float) -> void:
	var seconds: int = maxi(ceili(MatchService.time_remaining), 0)
	_timer_label.text = "%02d:%02d" % [floori(float(seconds) / 60.0), seconds % 60]


func _on_match_state_changed(state: StringName) -> void:
	_state_label.text = str(state).to_upper()


func _on_score_changed(scores: Dictionary) -> void:
	var entries: Array[String] = []
	for peer_id: Variant in scores.keys():
		entries.append("P%s: %s" % [peer_id, scores[peer_id]])
	_score_label.text = "  ".join(entries) if not entries.is_empty() else "No score"
