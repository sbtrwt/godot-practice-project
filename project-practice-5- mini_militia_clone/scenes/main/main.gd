extends Node2D
## Composition root for the first playable LAN prototype.

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player_entity.tscn")

@onready var _players: Node2D = $Players
@onready var _status_label: Label = $UI/StatusLabel
@onready var _ip_input: LineEdit = $UI/IPInput
@onready var _lobby_players_label: Label = $UI/LobbyPlayers
@onready var _network_recovery_button: Button = $UI/NetworkRecoveryButton

var _lobby_peer_ids: Array[int] = [1]


func _ready() -> void:
	NetworkService.session_state_changed.connect(_on_session_state_changed)
	NetworkService.peer_joined.connect(_on_peer_joined)
	NetworkService.peer_left.connect(_on_peer_left)
	NetworkService.local_session_ready.connect(_on_local_session_ready)
	EventBus.network_error.connect(_on_network_error)
	_refresh_lobby_players()
	_spawn_player(1)
	_status_label.text = "Offline — Host or join a LAN session"
	_network_recovery_button.visible = false


func _on_host_pressed() -> void:
	var error := NetworkService.host_game()
	if error != OK:
		_status_label.text = "Host failed: %s" % error_string(error)
		return
	_status_label.text = "Hosting at %s:%d" % [NetworkService.get_local_ipv4(), NetworkService.PORT]


func _on_join_pressed() -> void:
	var error := NetworkService.join_game(_ip_input.text.strip_edges())
	if error != OK:
		_status_label.text = "Join failed: %s" % error_string(error)
		return
	_status_label.text = "Connecting to %s" % _ip_input.text
	_network_recovery_button.visible = true


func _on_network_recovery_pressed() -> void:
	NetworkService.disconnect_session()
	_status_label.text = "Network reset — host or join again"
	_network_recovery_button.visible = false


func _on_network_error(code: StringName, message: String) -> void:
	_status_label.text = "%s: %s" % [str(code), message]
	_network_recovery_button.visible = true


func _on_start_match_pressed() -> void:
	if not multiplayer.is_server():
		_status_label.text = "Only the host can start the match"
		return
	MatchService.start_match()
	_status_label.text = "Match started"


func _spawn_player(peer_id: int) -> void:
	var player_name := "Player_%d" % peer_id
	if _players.has_node(player_name):
		return
	var player: Node2D = PLAYER_SCENE.instantiate() as Node2D
	if player == null:
		return
	player.name = player_name
	player.position = Vector2(320 + (peer_id - 1) * 100, 360)
	_players.add_child(player)
	player.set_multiplayer_authority(peer_id)
	EventBus.player_spawned.emit(peer_id)


func _on_session_state_changed(state: StringName) -> void:
	_status_label.text = "Session: %s" % state


func _on_peer_joined(peer_id: int) -> void:
	print("Peer joined: ", peer_id)
	if not _lobby_peer_ids.has(peer_id):
		_lobby_peer_ids.append(peer_id)
	_refresh_lobby_players()
	_spawn_player(peer_id)


func _on_peer_left(peer_id: int) -> void:
	print("Peer left: ", peer_id)
	_lobby_peer_ids.erase(peer_id)
	_refresh_lobby_players()
	var player := _players.get_node_or_null("Player_%d" % peer_id)
	if player != null:
		player.queue_free()


func _on_local_session_ready(peer_id: int) -> void:
	if not _lobby_peer_ids.has(peer_id):
		_lobby_peer_ids.append(peer_id)
	_refresh_lobby_players()
	_spawn_player(peer_id)


func _refresh_lobby_players() -> void:
	_lobby_peer_ids.sort()
	var names: Array[String] = []
	for peer_id: int in _lobby_peer_ids:
		names.append("Player %d%s" % [peer_id, " (Host)" if peer_id == 1 else ""])
	_lobby_players_label.text = "LAN PLAYERS  %d/6\n%s" % [names.size(), "\n".join(names)]
