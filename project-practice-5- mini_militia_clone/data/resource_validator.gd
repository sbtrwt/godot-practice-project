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
	return errors
