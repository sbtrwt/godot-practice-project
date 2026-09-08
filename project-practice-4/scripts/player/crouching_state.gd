class_name CrouchingState
extends PlayerState

func enter() -> void:
	player.play_animation("player_down")

func physics_update(delta: float) -> void:
	player.velocity.x = move_toward(player.velocity.x, 0.0, player.speed * delta * player.acceleration)
	if player.punch_started:
		player.change_state("punch")
	elif player.kick_started:
		player.change_state("kick")
	elif not player.down_pressed:
		player.change_state(player.get_ground_state())
