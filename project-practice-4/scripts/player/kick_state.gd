class_name KickState
extends PlayerState

var time_left: float = 0.0
var playing_normal: bool = false

func enter() -> void:
	player.velocity.x = 0.0
	playing_normal = false
	if not player.is_on_floor():
		player.play_animation("player_flying_kick")
		time_left = player.get_animation_duration("player_flying_kick")
	elif player.down_pressed:
		player.set_action_offset("player_sit_kick")
		player.play_animation("player_sit_kick")
		time_left = player.get_animation_duration("player_sit_kick")
	elif player.get_input_direction() != 0.0:
		player.set_action_offset("player_high_kick")
		player.play_animation("player_high_kick")
		time_left = player.get_animation_duration("player_high_kick")
	else:
		playing_normal = true
		player.play_animation("player_normal", true)
		time_left = player.get_animation_duration("player_normal")

func physics_update(delta: float) -> void:
	time_left -= delta
	player.velocity.x = move_toward(player.velocity.x, 0.0, player.speed * delta * player.acceleration)
	if time_left <= 0.0:
		if playing_normal:
			playing_normal = false
			player.set_action_offset("player_stand_kick")
			player.play_animation("player_stand_kick")
			time_left = player.get_animation_duration("player_stand_kick")
		else:
			player.change_state(player.get_ground_state() if player.is_on_floor() else "jump")
