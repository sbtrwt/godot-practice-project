extends Node
## Shared local input state for touch controls and presentation-independent gameplay.

var movement_axis: Vector2 = Vector2.ZERO
var aim_direction: Vector2 = Vector2.RIGHT
var aim_active: bool = false
var jetpack_active: bool = false
