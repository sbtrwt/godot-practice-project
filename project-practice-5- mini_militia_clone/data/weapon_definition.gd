class_name WeaponDefinition
extends Resource
## Data-only weapon tuning. Runtime cooldown belongs to WeaponComponent.

@export var weapon_id: StringName = &"pistol"
@export var display_name: String = "Pistol"
@export_range(1, 100) var damage: int = 25
@export_range(0.05, 10.0) var cooldown: float = 0.35
@export_range(1.0, 1000.0) var max_range: float = 420.0
@export_range(1, 200) var grenade_damage: int = 50
@export_range(10.0, 400.0) var grenade_radius: float = 180.0
@export_range(0.1, 10.0) var grenade_cooldown: float = 1.0
