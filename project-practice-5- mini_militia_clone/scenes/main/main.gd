extends Node2D
## Composition root for the first playable LAN prototype.

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player_entity.tscn")
const RESOURCE_VALIDATOR = preload("res://data/resource_validator.gd")
const PLAYER_DEFINITION = preload("res://data/default_player.tres")
const WEAPON_DEFINITION = preload("res://data/default_pistol.tres")
const ARENA_DEFINITION = preload("res://data/default_arena.tres")
const MATCH_DEFINITION = preload("res://data/default_match.tres")

@onready var _players: Node2D = $Players
@onready var _status_label: Label = $UI/StatusLabel
@onready var _ip_input: LineEdit = $UI/IPInput
@onready var _host_button: Button = $UI/HostButton
@onready var _join_button: Button = $UI/JoinButton
@onready var _lobby_players_label: Label = $UI/LobbyPlayers
@onready var _network_recovery_button: Button = $UI/NetworkRecoveryButton
@onready var _start_match_button: Button = $UI/StartMatchButton
@onready var _arena_walls: StaticBody2D = $ArenaWalls
@onready var _touch_controls: Control = $UI/TouchControls

var _lobby_peer_ids: Array[int] = [1]


func _ready() -> void:
	if not _validate_configured_resources():
		_status_label.text = "Configuration invalid — check ErrorService diagnostics"
		_host_button.disabled = true
		_join_button.disabled = true
		_start_match_button.disabled = true
		return
	_build_arena_collision()
	NetworkService.session_state_changed.connect(_on_session_state_changed)
	NetworkService.peer_joined.connect(_on_peer_joined)
	NetworkService.peer_left.connect(_on_peer_left)
	NetworkService.local_session_ready.connect(_on_local_session_ready)
	EventBus.network_error.connect(_on_network_error)
	MatchService.match_state_changed.connect(_on_match_state_changed)
	_refresh_lobby_players()
	_spawn_player(1)
	var saved_data: Dictionary = SaveService.load_game()
	var saved_ip: Variant = saved_data.get("last_host_ip", "")
	if saved_ip is String and not String(saved_ip).is_empty():
		_ip_input.text = String(saved_ip)
	_status_label.text = "Offline — Host or join a LAN session"
	_network_recovery_button.visible = false
	_touch_controls.visible = false
	_update_start_match_button()


func _validate_configured_resources() -> bool:
	var valid := true
	var validations: Array[Array] = [
		RESOURCE_VALIDATOR.validate_player(PLAYER_DEFINITION),
		RESOURCE_VALIDATOR.validate_weapon(WEAPON_DEFINITION),
		RESOURCE_VALIDATOR.validate_arena(ARENA_DEFINITION),
		RESOURCE_VALIDATOR.validate_match(MATCH_DEFINITION),
	]
	for errors: Array in validations:
		for message: String in errors:
			valid = false
			ErrorService.report(&"resource_validation_failed", message)
	return valid


func _build_arena_collision() -> void:
	for child: Node in _arena_walls.get_children():
		if child.name.begins_with("Platform"):
			child.queue_free()
	for index: int in ARENA_DEFINITION.platform_rects.size():
		var platform: Rect2 = ARENA_DEFINITION.platform_rects[index]
		var shape_node := CollisionShape2D.new()
		shape_node.name = "PlatformResource_%d" % index
		var shape := RectangleShape2D.new()
		shape.size = Vector2(platform.size.x, 24.0)
		shape_node.shape = shape
		shape_node.position = Vector2(platform.position.x + platform.size.x * 0.5, platform.position.y + 12.0)
		_arena_walls.add_child(shape_node)


func _on_host_pressed() -> void:
	ErrorService.clear()
	var error := NetworkService.host_game()
	if error != OK:
		_status_label.text = "Host failed: %s" % error_string(error)
		return
	_status_label.text = "Hosting at %s:%d" % [NetworkService.get_local_ipv4(), NetworkService.PORT]


func _on_join_pressed() -> void:
	ErrorService.clear()
	var error := NetworkService.join_game(_ip_input.text.strip_edges())
	if error != OK:
		_status_label.text = "Join failed: %s" % error_string(error)
		return
	_status_label.text = "Connecting to %s" % _ip_input.text
	_network_recovery_button.visible = true


func _on_network_recovery_pressed() -> void:
	NetworkService.disconnect_session()
	ErrorService.clear()
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
	var spawn_position: Vector2 = _spawn_position_for_peer(peer_id)
	player.position = spawn_position
	player.set("spawn_position", spawn_position)
	_players.add_child(player)
	player.set_multiplayer_authority(peer_id)
	EventBus.player_spawned.emit(peer_id)


func _spawn_position_for_peer(peer_id: int) -> Vector2:
	var spawn_points: Array = ARENA_DEFINITION.get("spawn_points")
	if spawn_points.is_empty():
		return Vector2(320.0, 360.0)
	return spawn_points[(peer_id - 1) % spawn_points.size()]


func _on_session_state_changed(state: StringName) -> void:
	_status_label.text = "Session: %s" % state
	_update_start_match_button()


func _on_match_state_changed(_state: StringName) -> void:
	_touch_controls.visible = _state == &"warmup" or _state == &"playing"
	_update_start_match_button()


func _update_start_match_button() -> void:
	if _start_match_button == null:
		return
	_start_match_button.disabled = not multiplayer.is_server() or MatchService.state != MatchService.MatchState.LOBBY


func _on_peer_joined(peer_id: int) -> void:
	print("Peer joined: ", peer_id)
	if not _lobby_peer_ids.has(peer_id):
		_lobby_peer_ids.append(peer_id)
	_refresh_lobby_players()
	_spawn_player(peer_id)
	MatchService.sync_peer(peer_id)


func _on_peer_left(peer_id: int) -> void:
	print("Peer left: ", peer_id)
	MatchService.remove_peer(peer_id)
	_lobby_peer_ids.erase(peer_id)
	_refresh_lobby_players()
	var player := _players.get_node_or_null("Player_%d" % peer_id)
	if player != null:
		player.queue_free()


func _on_local_session_ready(peer_id: int) -> void:
	if peer_id != 1:
		var save_error: Error = SaveService.save_game({"last_host_ip": _ip_input.text.strip_edges()})
		if save_error != OK:
			var message := "Could not persist LAN host address: %s" % error_string(save_error)
			ErrorService.report(&"save_failed", message)
			EventBus.network_error.emit(&"save_failed", message)
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
