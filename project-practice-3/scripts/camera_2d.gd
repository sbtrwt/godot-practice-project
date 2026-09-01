extends Camera2D

@export var INTENSITY_MULTIPLIER: float = 1.0

var shake_magnitude: float = 0.0
var shake_duration: float = 0.0
var shake_current_time: float = 0.0
var original_offset: Vector2 = Vector2.ZERO

func start_shake(magnitude: float, duration: float)-> void :
	if shake_current_time <= 0.0 or magnitude > shake_magnitude:
		shake_magnitude = magnitude * INTENSITY_MULTIPLIER
		shake_duration =duration
		shake_current_time = duration
		original_offset = self.offset

func _process(delta: float) -> void:
	if shake_current_time > 0:
		shake_current_time -= delta
		var current_magnitude = shake_magnitude * (shake_current_time / shake_duration)
		var shake_offset = Vector2(
			randf_range(-current_magnitude, current_magnitude),
			randf_range(-current_magnitude, current_magnitude)
		)
		self.offset = original_offset + shake_offset
		if shake_current_time <= 0:
			self.offset = original_offset
			shake_magnitude  = 0.0
			
