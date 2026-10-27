extends Node
## Cross-system notifications only. This node owns no gameplay state.

@warning_ignore_start("unused_signal")

signal player_spawned(peer_id: int)
signal player_removed(peer_id: int)
signal score_changed(peer_id: int, score: int)
signal match_state_changed(state: StringName)
signal network_error(code: StringName, message: String)
@warning_ignore_restore("unused_signal")
