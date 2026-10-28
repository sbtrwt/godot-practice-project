class_name ResourceValidator
extends RefCounted
## Pure validation rules for data Resources loaded at the composition root.


static func validate_player(resource: Resource) -> Array[String]:
	var errors: Array[String] = []
	if resource == null:
		return ["player definition is missing"]
	if float(resource.get("move_speed")) <= 0.0:
		errors.append("player move_speed must be positive")
	if float(resource.get("gravity")) <= 0.0:
		errors.append("player gravity must be positive")
	if float(resource.get("jetpack_thrust")) <= 0.0:
		errors.append("player jetpack_thrust must be positive")
	if int(resource.get("max_health")) <= 0:
		errors.append("player max_health must be positive")
	return errors


static func validate_weapon(resource: Resource) -> Array[String]:
	var errors: Array[String] = []
	if resource == null:
		return ["weapon definition is missing"]
	if StringName(resource.get("weapon_id")) == &"":
		errors.append("weapon weapon_id is required")
	if int(resource.get("damage")) <= 0:
		errors.append("weapon damage must be positive")
	if float(resource.get("cooldown")) <= 0.0:
		errors.append("weapon cooldown must be positive")
	if float(resource.get("max_range")) <= 0.0:
		errors.append("weapon max_range must be positive")
	if int(resource.get("grenade_damage")) <= 0:
		errors.append("weapon grenade_damage must be positive")
	if float(resource.get("grenade_radius")) <= 0.0:
		errors.append("weapon grenade_radius must be positive")
	if float(resource.get("grenade_cooldown")) <= 0.0:
		errors.append("weapon grenade_cooldown must be positive")
	return errors


static func validate_arena(resource: Resource) -> Array[String]:
	var errors: Array[String] = []
	if resource == null:
		return ["arena definition is missing"]
	var platforms: Variant = resource.get("platform_rects")
	var platform_array: Array = []
	if platforms is Array:
		platform_array = platforms
	if platform_array.is_empty():
		errors.append("arena requires at least one platform")
	for platform_value: Variant in platform_array:
		if not platform_value is Rect2:
			errors.append("arena platform must be a Rect2")
			continue
		var platform: Rect2 = platform_value
		if platform.size.x <= 0.0 or platform.size.y <= 0.0:
			errors.append("arena platform dimensions must be positive")
		elif not Rect2(0.0, 0.0, 1280.0, 720.0).encloses(platform):
			errors.append("arena platform must fit inside the playable bounds")
	var spawn_values: Variant = resource.get("spawn_points")
	var spawn_array: Array = spawn_values if spawn_values is Array else []
	if spawn_array.is_empty():
		errors.append("arena requires at least one spawn point")
	for spawn_value: Variant in spawn_array:
		if not spawn_value is Vector2:
			errors.append("arena spawn point must be a Vector2")
			continue
		if not Rect2(32.0, 32.0, 1216.0, 656.0).has_point(spawn_value):
			errors.append("arena spawn point must stay inside the playable bounds")
	return errors
