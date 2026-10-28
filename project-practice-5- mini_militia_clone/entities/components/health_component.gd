class_name HealthComponent
extends Node
## Reusable health component. It has no knowledge of its owning entity.

signal health_changed(current: int, maximum: int)
signal died

@export_range(1, 10000) var max_health: int = 100

var current_health: int


func _ready() -> void:
	current_health = max_health


## Applies validated damage and emits the resulting state.
func take_damage(amount: int) -> void:
	if amount <= 0 or current_health <= 0:
		return
	current_health = maxi(current_health - amount, 0)
	health_changed.emit(current_health, max_health)
	if current_health == 0:
		died.emit()


## Restores health without exceeding the configured maximum.
func heal(amount: int) -> void:
	if amount <= 0:
		return
	current_health = mini(current_health + amount, max_health)
	health_changed.emit(current_health, max_health)


## Applies a host-provided snapshot without granting local authority over damage.
func apply_replicated_health(current: int, maximum: int) -> void:
	max_health = maxi(maximum, 1)
	current_health = clampi(current, 0, max_health)
	health_changed.emit(current_health, max_health)
