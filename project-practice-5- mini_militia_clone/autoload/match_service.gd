extends Node
## Host-authoritative match lifecycle and score service.

signal match_state_changed(state: StringName)
signal score_changed(scores: Dictionary)
signal kill_feed_changed(entries: Array[String])
signal results_changed(summary: String)

enum MatchState { LOBBY, WARMUP, PLAYING, RESULTS }

const MATCH_DURATION: float = 120.0
const WARMUP_DURATION: float = 3.0
const SCORE_LIMIT: int = 10

var state: MatchState = MatchState.LOBBY
var time_remaining: float = 0.0
var scores: Dictionary = {}
var kill_feed: Array[String] = []
var results_summary: String = ""


func _process(delta: float) -> void:
	if not _is_server() or (state != MatchState.PLAYING and state != MatchState.WARMUP):
		return
	time_remaining = maxf(time_remaining - delta, 0.0)
	if state == MatchState.WARMUP and time_remaining <= 0.0:
		time_remaining = MATCH_DURATION
		_set_state(MatchState.PLAYING)
		return
	if time_remaining <= 0.0:
		_end_match()


## Starts a match. Only the host may change the authoritative state.
func start_match() -> void:
	if not _is_server():
		return
	scores.clear()
	kill_feed.clear()
	kill_feed_changed.emit(kill_feed.duplicate())
	results_summary = ""
	results_changed.emit(results_summary)
	time_remaining = WARMUP_DURATION
	_set_state(MatchState.WARMUP)


## Returns the session to the lobby for another round.
func return_to_lobby() -> void:
	if not _is_server():
		return
	time_remaining = 0.0
	scores.clear()
	kill_feed.clear()
	kill_feed_changed.emit(kill_feed.duplicate())
	results_summary = ""
	results_changed.emit(results_summary)
	_set_state(MatchState.LOBBY)


## Records a validated kill and ends the match at the score limit.
func report_kill(killer_id: int, victim_id: int) -> void:
	if not _is_server() or state != MatchState.PLAYING:
		return
	scores[killer_id] = int(scores.get(killer_id, 0)) + 1
	score_changed.emit(scores.duplicate())
	EventBus.score_changed.emit(killer_id, scores[killer_id])
	_publish_kill.rpc(killer_id, victim_id, scores[killer_id])
	if scores[killer_id] >= SCORE_LIMIT:
		_end_match()


@rpc("authority", "call_local", "reliable")
func _publish_kill(killer_id: int, victim_id: int, killer_score: int) -> void:
	var entry := "P%d eliminated P%d  (%d)" % [killer_id, victim_id, killer_score]
	kill_feed.push_front(entry)
	if kill_feed.size() > 4:
		kill_feed.pop_back()
	kill_feed_changed.emit(kill_feed.duplicate())


func _end_match() -> void:
	results_summary = _build_results_summary()
	results_changed.emit(results_summary)
	_set_state(MatchState.RESULTS)


func _build_results_summary() -> String:
	if scores.is_empty():
		return "DRAW — no eliminations"
	var highest_score: int = -1
	var winners: Array[String] = []
	for peer_id: Variant in scores.keys():
		var score: int = int(scores[peer_id])
		if score > highest_score:
			highest_score = score
			winners = ["P%s" % peer_id]
		elif score == highest_score:
			winners.append("P%s" % peer_id)
	if winners.size() > 1:
		return "DRAW — %s (%d)" % [" / ".join(winners), highest_score]
	return "WINNER %s — %d eliminations" % [winners[0], highest_score]


func _set_state(new_state: MatchState) -> void:
	state = new_state
	var state_name: String = str(MatchState.keys()[new_state]).to_snake_case()
	match_state_changed.emit(StringName(state_name))
	EventBus.match_state_changed.emit(StringName(state_name))


func _is_server() -> bool:
	return multiplayer == null or multiplayer.is_server()
