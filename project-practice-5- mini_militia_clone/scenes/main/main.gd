extends Node2D
## Composition root for the first playable LAN prototype.

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player_entity.tscn")

@onready var _players: Node2D = $Players
@onready var _status_label: Label = $UI/StatusLabel
@onready var _ip_input: LineEdit = $UI/IPInput


func _ready() -> void:
	NetworkService.session_state_changed.connect(_on_session_state_changed)
	NetworkService.peer_joined.connect(_on_peer_joined)
	NetworkService.peer_left.connect(_on_peer_left)
	NetworkService.local_session_ready.connect(_on_local_session_ready)
	_spawn_player(1)
	if multiplayer.is_server():
		MatchService.start_match()
	_status_label.text = "Offline — Host or join a LAN session"


func _on_host_pressed() -> void:
	var error := NetworkService.host_game()
	if error != OK:
		_status_label.text = "Host failed: %s" % error_string(error)
		return
	_status_label.text = "Hosting on UDP port %d" % NetworkService.PORT


func _on_join_pressed() -> void:
	var error := NetworkService.join_game(_ip_input.text.strip_edges())
	if error != OK:
		_status_label.text = "Join failed: %s" % error_string(error)
		return
	_status_label.text = "Connecting to %s" % _ip_input.text


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
	_spawn_player(peer_id)


func _on_peer_left(peer_id: int) -> void:
	print("Peer left: ", peer_id)
	var player := _players.get_node_or_null("Player_%d" % peer_id)
	if player != null:
		player.queue_free()


func _on_local_session_ready(peer_id: int) -> void:
	_spawn_player(peer_id)
