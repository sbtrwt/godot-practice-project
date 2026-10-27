extends Node
## Host-authoritative match lifecycle and score service.

signal match_state_changed(state: StringName)
signal score_changed(scores: Dictionary)

enum MatchState { LOBBY, WARMUP, PLAYING, RESULTS }

const MATCH_DURATION: float = 120.0
const SCORE_LIMIT: int = 10

var state: MatchState = MatchState.LOBBY
var time_remaining: float = 0.0
var scores: Dictionary = {}


func _process(delta: float) -> void:
	if not multiplayer.is_server() or state != MatchState.PLAYING:
		return
	time_remaining = maxf(time_remaining - delta, 0.0)
	if time_remaining <= 0.0:
		_end_match()


## Starts a match. Only the host may change the authoritative state.
func start_match() -> void:
	if not multiplayer.is_server():
		return
	scores.clear()
	time_remaining = MATCH_DURATION
	_set_state(MatchState.PLAYING)


## Records a validated kill and ends the match at the score limit.
func report_kill(killer_id: int) -> void:
	if not multiplayer.is_server() or state != MatchState.PLAYING:
		return
	scores[killer_id] = int(scores.get(killer_id, 0)) + 1
	score_changed.emit(scores.duplicate())
	EventBus.score_changed.emit(killer_id, scores[killer_id])
	if scores[killer_id] >= SCORE_LIMIT:
		_end_match()


func _end_match() -> void:
	_set_state(MatchState.RESULTS)


func _set_state(new_state: MatchState) -> void:
	state = new_state
	var state_name: String = str(MatchState.keys()[new_state]).to_snake_case()
	match_state_changed.emit(StringName(state_name))
	EventBus.match_state_changed.emit(StringName(state_name))
