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


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	_update_state(SessionState.OFFLINE)


## Starts a LAN server on the configured UDP port.
func host_game() -> Error:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(PORT, MAX_PLAYERS)
	if error != OK:
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
		EventBus.network_error.emit(&"network_join_failed", error_string(error))
		return error
	multiplayer.multiplayer_peer = peer
	_update_state(SessionState.CONNECTING)
	return OK


## Closes the current LAN session.
func disconnect_session() -> void:
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	_update_state(SessionState.OFFLINE)


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
	EventBus.network_error.emit(&"network_connection_failed", "The host rejected the connection.")
	disconnect_session()
