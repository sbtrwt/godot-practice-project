extends RigidBody2D

var launch_vector: Vector2 = Vector2.ZERO

func  initialize_launch(direction_vector: Vector2):
	launch_vector = direction_vector
	
func _ready() -> void:
	gravity_scale = 0
	apply_central_impulse(launch_vector)
	
	var lifetime_timer = Timer.new()
	lifetime_timer.one_shot = true
	lifetime_timer.wait_time = 3.0
	lifetime_timer.timeout.connect(queue_free)
	add_child(lifetime_timer) 
	lifetime_timer.start()
	
func _on_area_2d_body_entered(body):
	if body.is_in_group("entry"):
		pass
	else:
		queue_free()
