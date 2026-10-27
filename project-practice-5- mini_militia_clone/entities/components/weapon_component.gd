class_name WeaponComponent
extends Node
## Data-driven, cooldown-aware weapon component.

signal shot_requested

@export_range(0.05, 10.0) var cooldown: float = 0.35
@export_range(1, 100) var damage: int = 25
@export_range(1.0, 1000.0) var max_range: float = 420.0
@export var definition: Resource

var _cooldown_remaining: float = 0.0


func _ready() -> void:
	if definition == null:
		return
	cooldown = float(definition.get("cooldown"))
	damage = int(definition.get("damage"))
	max_range = float(definition.get("max_range"))


func _process(delta: float) -> void:
	_cooldown_remaining = maxf(_cooldown_remaining - delta, 0.0)


## Returns whether the weapon accepted a fire request.
func try_fire() -> bool:
	if _cooldown_remaining > 0.0:
		return false
	_cooldown_remaining = cooldown
	shot_requested.emit()
	return true
