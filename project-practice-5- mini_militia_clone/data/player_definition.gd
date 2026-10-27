class_name PlayerDefinition
extends Resource
## Data-only player tuning shared by player entity scenes.

@export var display_name: String = "Soldier"
@export_range(1.0, 1000.0) var move_speed: float = 260.0
@export_range(100.0, 3000.0) var gravity: float = 900.0
@export_range(100.0, 3000.0) var jetpack_thrust: float = 1500.0
@export_range(1, 1000) var max_health: int = 100
