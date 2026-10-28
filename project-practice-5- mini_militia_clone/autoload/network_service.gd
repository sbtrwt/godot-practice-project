extends Node
## LAN session service. The host is authoritative for gameplay decisions.

signal session_state_changed(state: StringName)
signal peer_joined(peer_id: int)
signal peer_left(peer_id: int)
signal local_session_ready(peer_id: int)

const PORT: int = 7777
const MAX_PLAYERS: int = 6

enum SessionState { OFFLINE, HOSTING, CONNECTING, CONNECTED }

var session_state: SessionState = SessionState.OFFLINE
var simulation_enabled: bool = OS.is_debug_build()
var simulated_latency_ms: int = 0
var simulated_packet_loss_percent: int = 0
var _packet_counter: int = 0


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	_update_state(SessionState.OFFLINE)


## Starts a LAN server on the configured UDP port.
func host_game() -> Error:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(PORT, MAX_PLAYERS)
	if error != OK:
		ErrorService.report(&"network_host_failed", error_string(error))
		EventBus.network_error.emit(&"network_host_failed", error_string(error))
		return error
	multiplayer.multiplayer_peer = peer
	_update_state(SessionState.HOSTING)
	return OK


## Connects to a host on the same Wi-Fi network.
func join_game(ip_address: String) -> Error:
	if ip_address.is_empty():
		return ERR_INVALID_PARAMETER
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(ip_address, PORT)
	if error != OK:
		ErrorService.report(&"network_join_failed", error_string(error))
		EventBus.network_error.emit(&"network_join_failed", error_string(error))
		return error
	multiplayer.multiplayer_peer = peer
	_update_state(SessionState.CONNECTING)
	return OK


## Returns the first private IPv4 address suitable for a LAN client.
func get_local_ipv4() -> String:
	for address: String in IP.get_local_addresses():
		if address.contains(":"):
			continue
		if not _is_private_ipv4(address):
			continue
		return address
	return "unavailable"


func _is_private_ipv4(address: String) -> bool:
	var octets := address.split(".")
	if octets.size() != 4:
		return false
	var first := int(octets[0])
	var second := int(octets[1])
	if first == 10 or first == 192 and second == 168:
		return true
	return first == 172 and second >= 16 and second <= 31


## Closes the current LAN session.
func disconnect_session() -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	_update_state(SessionState.OFFLINE)


## Debug-only deterministic packet simulation used by local soak tests.
func configure_simulation(enabled: bool, latency_ms: int, packet_loss_percent: int) -> void:
	simulation_enabled = enabled and OS.is_debug_build()
	simulated_latency_ms = clampi(latency_ms, 0, 2000)
	simulated_packet_loss_percent = clampi(packet_loss_percent, 0, 100)


func should_drop_packet() -> bool:
	if not simulation_enabled or simulated_packet_loss_percent <= 0:
		return false
	_packet_counter += 1
	return (_packet_counter % 100) < simulated_packet_loss_percent


func simulated_latency_seconds() -> float:
	if not simulation_enabled:
		return 0.0
	return float(simulated_latency_ms) / 1000.0


func _update_state(new_state: SessionState) -> void:
	session_state = new_state
	var state_name: String = str(SessionState.keys()[new_state]).to_snake_case()
	session_state_changed.emit(StringName(state_name))


func _on_peer_connected(peer_id: int) -> void:
	peer_joined.emit(peer_id)
	EventBus.player_spawned.emit(peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	peer_left.emit(peer_id)
	EventBus.player_removed.emit(peer_id)


func _on_connected_to_server() -> void:
	_update_state(SessionState.CONNECTED)
	local_session_ready.emit(multiplayer.get_unique_id())


func _on_connection_failed() -> void:
	ErrorService.report(&"network_connection_failed", "The host rejected the connection.")
	EventBus.network_error.emit(&"network_connection_failed", "The host rejected the connection.")
	disconnect_session()


func _on_server_disconnected() -> void:
	ErrorService.report(&"network_server_disconnected", "The host ended the LAN session.")
	EventBus.network_error.emit(&"network_server_disconnected", "The host ended the LAN session.")
	disconnect_session()
