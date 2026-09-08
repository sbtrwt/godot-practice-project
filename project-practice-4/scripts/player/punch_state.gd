class_name PunchState
extends PlayerState

var time_left: float = 0.0

func enter() -> void:
	player.velocity.x = 0.0
	if player.down_pressed:
		player.set_action_offset("player_sit_punch")
		player.play_animation("player_sit_punch")
		time_left = player.get_animation_duration("player_sit_punch")
	else:
		player.execute_punch()
		time_left = player.get_animation_duration("player_stand_punch")

func physics_update(delta: float) -> void:
	time_left -= delta
	player.velocity.x = move_toward(player.velocity.x, 0.0, player.speed * delta * player.acceleration)
	if time_left <= 0.0:
		player.change_state(player.get_ground_state() if player.is_on_floor() else "jump")
