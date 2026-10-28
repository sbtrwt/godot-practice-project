extends SceneTree
## Dependency-free headless smoke tests for pure gameplay components.

const HealthComponentScript = preload("res://entities/components/health_component.gd")
const WeaponComponentScript = preload("res://entities/components/weapon_component.gd")
const SaveServiceScript = preload("res://autoload/save_service.gd")
const ResourceValidator = preload("res://data/resource_validator.gd")
const PlayerDefinitionResource = preload("res://data/default_player.tres")
const WeaponDefinitionResource = preload("res://data/default_pistol.tres")
const ArenaDefinitionResource = preload("res://data/default_arena.tres")

var _failures: int = 0


func _initialize() -> void:
	_test_health_component()
	_test_weapon_cooldown()
	_test_save_migration()
	_test_network_simulation()
	_test_error_service()
	_test_resource_validation()
	_test_network_soak()
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
	network.queue_free()


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
	_assert(ResourceValidator.validate_arena(ArenaDefinitionResource).is_empty(), "default arena resource validates")


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


func _assert(condition: bool, description: String) -> void:
	if condition:
		print("PASS: %s" % description)
	else:
		printerr("FAIL: %s" % description)
		_failures += 1
