class_name PunchState
extends PlayerState

var time_left: float = 0.0
var recovering: bool = false
var playing_normal: bool = false

func enter() -> void:
	player.velocity.x = 0.0
	recovering = false
	playing_normal = false
	if player.down_pressed:
		player.set_action_offset("player_sit_punch")
		player.play_animation("player_sit_punch")
		time_left = player.get_animation_duration("player_sit_punch")
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
			player.execute_punch()
			time_left = player.get_animation_duration("player_stand_punch")
		elif not recovering:
			recovering = true
			player.reset_sprite_offset()
			if player.down_pressed:
				player.play_animation("player_sit_punch")
				time_left = player.get_animation_duration("player_sit_punch")
			else:
				player.play_animation("player_stand_punch")
				time_left = player.get_animation_duration("player_stand_punch")	
			
		elif player.is_on_floor():
			if player.down_pressed:
				player.change_state("crouching")
			else:
				player.change_state(player.get_ground_state())
		else:
			player.change_state("jump")
