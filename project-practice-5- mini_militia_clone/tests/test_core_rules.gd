extends SceneTree
## Dependency-free headless smoke tests for pure gameplay components.

const HealthComponentScript = preload("res://entities/components/health_component.gd")
const WeaponComponentScript = preload("res://entities/components/weapon_component.gd")
const HurtboxComponentScript = preload("res://entities/components/hurtbox_component.gd")
const SaveServiceScript = preload("res://autoload/save_service.gd")
const ResourceValidator = preload("res://data/resource_validator.gd")
const PlayerDefinitionResource = preload("res://data/default_player.tres")
const WeaponDefinitionResource = preload("res://data/default_pistol.tres")
const ArenaDefinitionResource = preload("res://data/default_arena.tres")
const MatchDefinitionResource = preload("res://data/default_match.tres")

var _failures: int = 0


func _initialize() -> void:
	_test_health_component()
	_test_weapon_cooldown()
	_test_hurtbox_signal()
	_test_save_migration()
	_test_network_simulation()
	_test_error_service()
	_test_resource_validation()
	_test_network_soak()
	_test_network_timeout()
	_test_match_warmup()
	_test_kill_feed()
	if _failures == 0:
		print("CORE_RULE_TESTS_PASS")
		quit(0)
	else:
		printerr("CORE_RULE_TESTS_FAIL count=%d" % _failures)
		quit(1)


func _test_health_component() -> void:
	var health: Node = HealthComponentScript.new()
	health.set("max_health", 100)
	root.add_child(health)
	await process_frame
	_assert(int(health.get("current_health")) == 100, "health initializes to max")
	health.call("take_damage", 35)
	_assert(int(health.get("current_health")) == 65, "damage reduces health")
	health.call("take_damage", 1000)
	_assert(int(health.get("current_health")) == 0, "damage clamps at zero")
	health.call("heal", 20)
	_assert(int(health.get("current_health")) == 20, "heal restores health")
	health.call("heal", 1000)
	_assert(int(health.get("current_health")) == 100, "heal clamps at max")
	health.call("apply_replicated_health", 25, 80)
	_assert(int(health.get("current_health")) == 25, "replicated health applies current value")
	_assert(int(health.get("max_health")) == 80, "replicated health applies maximum")
	health.queue_free()


func _test_weapon_cooldown() -> void:
	var weapon: Node = WeaponComponentScript.new()
	weapon.set("cooldown", 0.25)
	root.add_child(weapon)
	await process_frame
	_assert(bool(weapon.call("try_fire")), "weapon accepts first shot")
	_assert(not bool(weapon.call("try_fire")), "weapon rejects shot during cooldown")
	weapon.call("_process", 0.25)
	_assert(bool(weapon.call("try_fire")), "weapon accepts shot after cooldown")
	weapon.queue_free()


func _test_hurtbox_signal() -> void:
	var hurtbox: HurtboxComponent = HurtboxComponentScript.new()
	root.add_child(hurtbox)
	var received: Array[Variant] = []
	hurtbox.hit_received.connect(func(amount: int, attacker_id: int) -> void:
		received.append([amount, attacker_id])
	)
	hurtbox.call("receive_hit", 35, 7)
	hurtbox.call("receive_hit", 0, 8)
	_assert(received.size() == 1, "hurtbox ignores non-positive damage")
	_assert(received[0] == [35, 7], "hurtbox forwards damage and attacker identity")
	hurtbox.queue_free()


func _test_save_migration() -> void:
	var save_service: Node = SaveServiceScript.new()
	root.add_child(save_service)
	var migrated: Dictionary = save_service.call("migrate_payload", {
		"version": 1,
		"data": {"credits": 250},
	})
	var settings: Dictionary = {}
	var settings_value: Variant = migrated.get("settings", {})
	if settings_value is Dictionary:
		settings = settings_value
	var profile: Dictionary = {}
	var profile_value: Variant = migrated.get("profile", {})
	if profile_value is Dictionary:
		profile = profile_value
	_assert(migrated.get("credits", 0) == 250, "save migration preserves existing data")
	_assert(settings.get("control_scheme", "") == "twin_stick", "save migration adds control defaults")
	_assert(profile.get("display_name", "") == "Player", "save migration adds profile defaults")
	save_service.queue_free()


func _test_network_simulation() -> void:
	var network: Node = root.get_node("NetworkService")
	network.call("configure_simulation", true, 120, 100)
	_assert(is_equal_approx(float(network.call("simulated_latency_seconds")), 0.12), "network simulation exposes configured latency")
	_assert(bool(network.call("should_drop_packet")), "network simulation drops packets at 100 percent loss")
	network.call("configure_simulation", false, 0, 0)
	network.call("configure_simulation", true, 120, 100)
	_assert(bool(network.call("should_drop_packet")), "network simulation reset remains deterministic")
	network.call("configure_simulation", false, 0, 0)


func _test_error_service() -> void:
	var errors: Node = root.get_node("ErrorService")
	errors.call("clear")
	for index: int in 25:
		errors.call("report", StringName("test_%d" % index), "diagnostic")
	var records: Array = errors.get("records")
	_assert(records.size() == 20, "error service bounds diagnostic history")
	var latest: Dictionary = errors.call("latest")
	_assert(latest.get("code", &"") == &"test_24", "error service exposes latest diagnostic")
	errors.call("clear")


func _test_resource_validation() -> void:
	_assert(ResourceValidator.validate_player(PlayerDefinitionResource).is_empty(), "default player resource validates")
	_assert(ResourceValidator.validate_weapon(WeaponDefinitionResource).is_empty(), "default weapon resource validates")
	var invalid_weapon: Resource = WeaponDefinitionResource.duplicate(true)
	invalid_weapon.set("grenade_radius", 0.0)
	_assert(not ResourceValidator.validate_weapon(invalid_weapon).is_empty(), "weapon validator rejects invalid grenade tuning")
	_assert(ResourceValidator.validate_arena(ArenaDefinitionResource).is_empty(), "default arena resource validates")
	_assert(ResourceValidator.validate_match(MatchDefinitionResource).is_empty(), "default match resource validates")
	var invalid_match: Resource = MatchDefinitionResource.duplicate(true)
	invalid_match.set("score_limit", 0)
	_assert(not ResourceValidator.validate_match(invalid_match).is_empty(), "match validator rejects invalid score limit")
	var invalid_arena: Resource = ArenaDefinitionResource.duplicate(true)
	var invalid_platforms: Array[Rect2] = [Rect2(-10.0, 0.0, 40.0, 40.0)]
	invalid_arena.set("platform_rects", invalid_platforms)
	_assert(not ResourceValidator.validate_arena(invalid_arena).is_empty(), "arena validator rejects out-of-bounds geometry")
	var invalid_spawns: Array[Vector2] = [Vector2(-20.0, 360.0)]
	var invalid_spawn_arena: Resource = ArenaDefinitionResource.duplicate(true)
	invalid_spawn_arena.set("spawn_points", invalid_spawns)
	_assert(not ResourceValidator.validate_arena(invalid_spawn_arena).is_empty(), "arena validator rejects out-of-bounds spawns")


func _test_network_soak() -> void:
	var network: Node = root.get_node("NetworkService")
	network.call("configure_simulation", true, 180, 25)
	var dropped: int = 0
	for _index: int in 1000:
		if bool(network.call("should_drop_packet")):
			dropped += 1
	_assert(dropped >= 240 and dropped <= 260, "network soak stays within configured packet-loss envelope")
	_assert(is_equal_approx(float(network.call("simulated_latency_seconds")), 0.18), "network soak preserves configured latency")
	network.call("configure_simulation", false, 0, 0)


func _test_network_timeout() -> void:
	var network: Node = root.get_node("NetworkService")
	var errors: Node = root.get_node("ErrorService")
	errors.call("clear")
	network.set("session_state", 2)
	network.call("_process", 8.1)
	_assert(int(network.get("session_state")) == 0, "network timeout returns to offline state")
	var latest: Dictionary = errors.call("latest")
	_assert(latest.get("code", &"") == &"network_connection_timeout", "network timeout records diagnostic")
	errors.call("clear")
	var invalid_result: int = int(network.call("join_game", "not-an-ip"))
	_assert(invalid_result == ERR_INVALID_PARAMETER, "invalid LAN address is rejected locally")
	latest = errors.call("latest")
	_assert(latest.get("code", &"") == &"network_invalid_address", "invalid LAN address records diagnostic")
	network.set("session_state", 2)
	network.call("disconnect_session")
	_assert(int(network.get("session_state")) == 0, "network reset returns to offline before retry")


func _test_match_warmup() -> void:
	var match_service: Node = root.get_node("MatchService")
	match_service.call("return_to_lobby")
	match_service.call("start_match")
	match_service.call("_process", 3.1)
	match_service.call("report_kill", 1, 2)
	match_service.call("report_kill", 1, 3)
	match_service.call("_end_match")
	_assert(str(match_service.get("results_summary")).contains("WINNER P1"), "results identify the authoritative winner")
	match_service.call("return_to_lobby")


func _test_kill_feed() -> void:
	var match_service: Node = root.get_node("MatchService")
	match_service.call("return_to_lobby")
	match_service.call("start_match")
	match_service.call("_process", 3.1)
	for index: int in 5:
		match_service.call("report_kill", 1, index + 2)
	var feed: Array = []
	var feed_value: Variant = match_service.get("kill_feed")
	if feed_value is Array:
		for entry: Variant in feed_value:
			feed.append(entry)
	_assert(feed.size() == 4, "kill feed is bounded to four entries")
	_assert(str(feed[0]).contains("P6"), "kill feed keeps newest elimination first")
	match_service.call("return_to_lobby")
	var cleared_feed_value: Variant = match_service.get("kill_feed")
	var cleared_feed: Array = []
	if cleared_feed_value is Array:
		for entry: Variant in cleared_feed_value:
			cleared_feed.append(entry)
	_assert(cleared_feed.is_empty(), "returning to lobby clears kill feed")
	match_service.call("start_match")
	_assert(int(match_service.get("state")) == 1, "match start enters warmup state")
	_assert(is_equal_approx(float(match_service.get("time_remaining")), 3.0), "warmup starts with configured duration")
	match_service.call("_process", 3.1)
	_assert(int(match_service.get("state")) == 2, "warmup transitions to playing state")
	match_service.call("_publish_score", {1: 3})
	var replicated_scores: Dictionary = {}
	var replicated_scores_value: Variant = match_service.get("scores")
	if replicated_scores_value is Dictionary:
		replicated_scores = replicated_scores_value
	_assert(int(replicated_scores.get(1, 0)) == 3, "score replication applies snapshots")
	match_service.call("_publish_state", 2, 42.0, "")
	_assert(is_equal_approx(float(match_service.get("time_remaining")), 42.0), "state replication applies authoritative timer")
	var replicated_feed_entries: Array[String] = ["P1 eliminated P2  (1)"]
	match_service.call("_publish_feed", replicated_feed_entries)
	var replicated_feed: Array = []
	var replicated_feed_value: Variant = match_service.get("kill_feed")
	if replicated_feed_value is Array:
		for entry: Variant in replicated_feed_value:
			replicated_feed.append(entry)
	_assert(replicated_feed.size() == 1, "late-join feed snapshot applies")
	match_service.call("_publish_score", {2: 4})
	match_service.call("remove_peer", 2)
	var remaining_scores: Dictionary = {}
	var remaining_scores_value: Variant = match_service.get("scores")
	if remaining_scores_value is Dictionary:
		remaining_scores = remaining_scores_value
	_assert(not remaining_scores.has(2), "disconnect removes stale peer score")
	match_service.call("return_to_lobby")


func _assert(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
	else:
		printerr("FAIL: %s" % description)
		_failures += 1
