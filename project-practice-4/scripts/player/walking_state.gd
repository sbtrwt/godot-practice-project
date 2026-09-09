class_name WalkingState
extends GroundState

func enter() -> void:
	player.reset_sprite_offset()
	player.play_animation("player_walk")
