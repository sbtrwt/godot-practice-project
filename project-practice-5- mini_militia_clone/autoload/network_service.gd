extends Node
## LAN session service. The host is authoritative for gameplay decisions.

signal session_state_changed(state: StringName)
signal peer_joined(peer_id: int)
signal peer_left(peer_id: int)
signal local_session_ready(peer_id: int)

const PORT: int = 7777
const MAX_PLAYERS: int = 6
const PROTOCOL_VERSION: int = 1
const CONNECT_TIMEOUT_SECONDS: float = 8.0

enum SessionState { OFFLINE, HOSTING, CONNECTING, CONNECTED }

var session_state: SessionState = SessionState.OFFLINE
var simulation_enabled: bool = OS.is_debug_build()
var simulated_latency_ms: int = 0
var simulated_packet_loss_percent: int = 0
var _packet_counter: int = 0
var _connection_elapsed: float = 0.0


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	_update_state(SessionState.OFFLINE)


func _process(delta: float) -> void:
	if session_state != SessionState.CONNECTING:
		return
	_connection_elapsed += delta
	if _connection_elapsed < CONNECT_TIMEOUT_SECONDS:
		return
	var message := "Connection timed out after %d seconds." % int(CONNECT_TIMEOUT_SECONDS)
	ErrorService.report(&"network_connection_timeout", message)
	EventBus.network_error.emit(&"network_connection_timeout", message)
	disconnect_session()


## Starts a LAN server on the configured UDP port.
func host_game() -> Error:
	if session_state != SessionState.OFFLINE:
		disconnect_session()
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
	ip_address = ip_address.strip_edges()
	if ip_address.is_empty() or not _is_valid_ipv4(ip_address):
		var message := "Enter a valid LAN IPv4 address."
		ErrorService.report(&"network_invalid_address", message)
		EventBus.network_error.emit(&"network_invalid_address", message)
		return ERR_INVALID_PARAMETER
	if session_state != SessionState.OFFLINE:
		disconnect_session()
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(ip_address, PORT)
	if error != OK:
		ErrorService.report(&"network_join_failed", error_string(error))
		EventBus.network_error.emit(&"network_join_failed", error_string(error))
		return error
	multiplayer.multiplayer_peer = peer
	_connection_elapsed = 0.0
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
	var octets: PackedStringArray = address.split(".")
	if not _is_valid_ipv4(address):
		return false
	var first := int(octets[0])
	var second := int(octets[1])
	if first == 10 or first == 192 and second == 168:
		return true
	return first == 172 and second >= 16 and second <= 31


func _is_valid_ipv4(address: String) -> bool:
	var octets: PackedStringArray = address.split(".")
	if octets.size() != 4:
		return false
	for octet: String in octets:
		if not octet.is_valid_int() or int(octet) < 0 or int(octet) > 255:
			return false
	return true


## Closes the current LAN session.
func disconnect_session() -> void:
	_connection_elapsed = 0.0
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	_update_state(SessionState.OFFLINE)


## Debug-only deterministic packet simulation used by local soak tests.
func configure_simulation(enabled: bool, latency_ms: int, packet_loss_percent: int) -> void:
	simulation_enabled = enabled and OS.is_debug_build()
	simulated_latency_ms = clampi(latency_ms, 0, 2000)
	simulated_packet_loss_percent = clampi(packet_loss_percent, 0, 100)
	_packet_counter = 0


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
	_send_protocol_version.rpc_id(peer_id, PROTOCOL_VERSION)
	peer_joined.emit(peer_id)
	EventBus.player_spawned.emit(peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	peer_left.emit(peer_id)
	EventBus.player_removed.emit(peer_id)


func _on_connected_to_server() -> void:
	_connection_elapsed = 0.0
	_update_state(SessionState.CONNECTED)
	_send_protocol_version.rpc_id(1, PROTOCOL_VERSION)
	local_session_ready.emit(multiplayer.get_unique_id())


@rpc("any_peer", "call_local", "reliable")
func _send_protocol_version(version: int) -> void:
	if version == PROTOCOL_VERSION:
		return
	var message := "Incompatible LAN build (host protocol %d, local protocol %d)." % [version, PROTOCOL_VERSION]
	ErrorService.report(&"network_protocol_mismatch", message)
	EventBus.network_error.emit(&"network_protocol_mismatch", message)
	if multiplayer.is_server():
		var sender_id := multiplayer.get_remote_sender_id()
		if sender_id > 0 and multiplayer.multiplayer_peer != null:
			multiplayer.multiplayer_peer.disconnect_peer(sender_id)
	else:
		disconnect_session()


func _on_connection_failed() -> void:
	ErrorService.report(&"network_connection_failed", "The host rejected the connection.")
	EventBus.network_error.emit(&"network_connection_failed", "The host rejected the connection.")
	disconnect_session()


func _on_server_disconnected() -> void:
	ErrorService.report(&"network_server_disconnected", "The host ended the LAN session.")
	EventBus.network_error.emit(&"network_server_disconnected", "The host ended the LAN session.")
	disconnect_session()
