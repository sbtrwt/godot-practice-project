extends Node
## Presentation-facing match state adapter. It formats service state for the HUD.

signal state_changed(state: StringName, can_return_to_lobby: bool)
signal timer_changed(text: String)
signal score_changed(text: String)
signal kill_feed_changed(text: String)

var _last_timer_text: String = ""


func _ready() -> void:
	MatchService.match_state_changed.connect(_on_match_state_changed)
	MatchService.score_changed.connect(_on_score_changed)
	MatchService.kill_feed_changed.connect(_on_kill_feed_changed)
	_on_match_state_changed(&"lobby")
	_on_score_changed({})
	_on_kill_feed_changed([])


func _process(_delta: float) -> void:
	var seconds: int = maxi(ceili(MatchService.time_remaining), 0)
	var timer_text: String = "%02d:%02d" % [floori(float(seconds) / 60.0), seconds % 60]
	if timer_text == _last_timer_text:
		return
	_last_timer_text = timer_text
	timer_changed.emit(timer_text)


func return_to_lobby() -> void:
	MatchService.return_to_lobby()


func _on_match_state_changed(state: StringName) -> void:
	state_changed.emit(state, state == &"results" and multiplayer.is_server())


func _on_score_changed(scores: Dictionary) -> void:
	var entries: Array[String] = []
	for peer_id: Variant in scores.keys():
		entries.append("P%s: %s" % [peer_id, scores[peer_id]])
	score_changed.emit("  ".join(entries) if not entries.is_empty() else "No score")


func _on_kill_feed_changed(entries: Array[String]) -> void:
	kill_feed_changed.emit("\n".join(entries))
