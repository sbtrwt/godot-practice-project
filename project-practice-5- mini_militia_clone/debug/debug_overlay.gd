extends Label
## Development-only network and runtime observability overlay.

@export var update_interval: float = 0.25

var _elapsed: float = 0.0


func _ready() -> void:
	visible = OS.is_debug_build()
	text = "Debug overlay"


func _process(delta: float) -> void:
	if not visible:
		return
	_elapsed += delta
	if _elapsed < update_interval:
		return
	_elapsed = 0.0
	var peer_count: int = multiplayer.get_peers().size()
	var unique_id: int = multiplayer.get_unique_id()
	var session: String = str(NetworkService.session_state)
	text = "NET session=%s peer_id=%d peers=%d fps=%d sim=%s lag=%dms loss=%d%%" % [
		session,
		unique_id,
		peer_count,
		Engine.get_frames_per_second(),
		"on" if NetworkService.simulation_enabled else "off",
		NetworkService.simulated_latency_ms,
		NetworkService.simulated_packet_loss_percent,
	]
