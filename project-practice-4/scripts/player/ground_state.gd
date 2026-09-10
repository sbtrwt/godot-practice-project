class_name GroundState
extends PlayerState

func physics_update(delta: float) -> void:
	if player.is_on_floor() and player.down_pressed and player.punch_started:
		player.execute_command(player.punch_command)
	elif player.is_on_floor() and player.down_pressed and player.kick_started:
		player.execute_command(player.kick_command)
	elif not player.is_on_floor() and player.kick_started:
		player.execute_command(player.kick_command)
	elif player.is_on_floor() and player.punch_started:
		player.execute_command(player.punch_command)
	elif player.is_on_floor() and player.kick_started:
		player.execute_command(player.kick_command)
	elif player.is_on_floor() and player.jump_started:
		player.execute_command(player.jump_command)
	elif player.is_on_floor() and player.down_pressed:
		player.velocity.x = move_toward(player.velocity.x, 0.0, player.speed * delta * player.acceleration)
		player.change_state("crouching")
	else:
		player.move_horizontally(delta)
		if not player.is_on_floor():
			player.change_state("jump")
		else:
			player.change_state(player.get_ground_state())
