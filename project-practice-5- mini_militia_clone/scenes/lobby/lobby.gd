extends Control
## Dedicated LAN lobby with automatic nearby-server discovery.

const GAME_SCENE: String = "res://scenes/main/main.tscn"

@onready var _status: Label = %Status
@onready var _ip_input: LineEdit = %IpInput
@onready var _server_list: ItemList = %ServerList
@onready var _host_button: Button = %HostButton
@onready var _join_button: Button = %JoinButton
@onready var _start_button: Button = %StartButton
@onready var _players_label: Label = %Players

var _servers: Array[Dictionary] = []


func _ready() -> void:
	NetworkService.server_discovered.connect(_on_server_discovered)
	NetworkService.discovery_changed.connect(_on_discovery_changed)
	NetworkService.session_state_changed.connect(_on_session_state_changed)
	NetworkService.local_session_ready.connect(_on_local_session_ready)
	NetworkService.peer_joined.connect(_on_peer_joined)
	NetworkService.peer_left.connect(_on_peer_left)
	EventBus.network_error.connect(_on_network_error)
	MatchService.match_state_changed.connect(_on_match_state_changed)
	NetworkService.start_server_discovery()
	_start_button.disabled = true
	_status.text = "Scanning nearby LAN hosts..."
	_refresh_player_count()


func _exit_tree() -> void:
	NetworkService.stop_server_discovery()


func _on_refresh_pressed() -> void:
	NetworkService.start_server_discovery()
	_status.text = "Scanning nearby LAN hosts..."


func _on_host_pressed() -> void:
	var error: Error = NetworkService.host_game()
	if error != OK:
		_status.text = "Host failed: %s" % error_string(error)
		return
	_start_button.disabled = false
	_status.text = "Hosting on %s:%d — waiting for players" % [NetworkService.get_local_ipv4(), NetworkService.PORT]


func _on_join_pressed() -> void:
	var address: String = _ip_input.text.strip_edges()
	var selected: PackedInt32Array = _server_list.get_selected_items()
	if not selected.is_empty() and selected[0] < _servers.size():
		address = String(_servers[selected[0]].get("address", address))
	if address.is_empty():
		_status.text = "Select a nearby host or enter an IP address"
		return
	var error: Error = NetworkService.join_game(address)
	if error != OK:
		_status.text = "Join failed: %s" % error_string(error)
		return
	_status.text = "Connecting to %s:%d..." % [address, NetworkService.PORT]


func _on_start_pressed() -> void:
	if not multiplayer.is_server():
		return
	MatchService.start_match()


func _on_server_discovered(_server: Dictionary) -> void:
	_servers = NetworkService.get_discovered_servers()
	_refresh_server_list()


func _on_discovery_changed(servers: Array[Dictionary]) -> void:
	_servers = servers
	_refresh_server_list()


func _refresh_server_list() -> void:
	_server_list.clear()
	for server: Dictionary in _servers:
		_server_list.add_item("%s   %d/6 players" % [server["name"], server["players"]])


func _on_session_state_changed(state: StringName) -> void:
	if state == &"hosting":
		_start_button.disabled = false
	elif state == &"connecting":
		_host_button.disabled = true
		_join_button.disabled = true


func _on_local_session_ready(_peer_id: int) -> void:
	if multiplayer.is_server():
		_start_button.disabled = false
	else:
		_status.text = "Connected — waiting for the host to start"
	_refresh_player_count()


func _on_peer_joined(_peer_id: int) -> void:
	_refresh_player_count()


func _on_peer_left(_peer_id: int) -> void:
	_refresh_player_count()


func _refresh_player_count() -> void:
	var count: int = multiplayer.get_peers().size()
	if NetworkService.session_state != NetworkService.SessionState.OFFLINE:
		count += 1
	_players_label.text = "PLAYERS  %d/6" % count


func _on_network_error(code: StringName, message: String) -> void:
	_status.text = "%s: %s" % [str(code), message]
	_host_button.disabled = false
	_join_button.disabled = false


func _on_match_state_changed(state: StringName) -> void:
	if state == &"warmup" or state == &"playing":
		_change_to_game()


func _change_to_game() -> void:
	if not is_inside_tree():
		return
	if get_tree().current_scene == self:
		get_tree().change_scene_to_file(GAME_SCENE)
