class_name GroundState
extends PlayerState

func physics_update(delta: float) -> void:
	if player.is_on_floor() and player.down_pressed and player.punch_started:
		player.change_state("punch")
	elif player.is_on_floor() and player.down_pressed and player.kick_started:
		player.change_state("kick")
	elif not player.is_on_floor() and player.kick_started:
		player.change_state("kick")
	elif player.is_on_floor() and player.punch_started:
		player.change_state("punch")
	elif player.is_on_floor() and player.kick_started:
		player.change_state("kick")
	elif player.is_on_floor() and Input.is_action_just_pressed("ui_up"):
		player.player_jump()
	elif player.is_on_floor() and player.down_pressed:
		player.velocity.x = move_toward(player.velocity.x, 0.0, player.speed * delta * player.acceleration)
		player.change_state("crouching")
	else:
		player.move_horizontally(delta)
		if not player.is_on_floor():
			player.change_state("jump")
		else:
			player.change_state(player.get_ground_state())
