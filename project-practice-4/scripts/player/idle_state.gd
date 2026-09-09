class_name IdleState
extends GroundState

func enter() -> void:
	player.reset_sprite_offset()
	player.play_animation("player_normal")
