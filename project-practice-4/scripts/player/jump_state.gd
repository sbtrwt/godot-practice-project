class_name JumpState
extends PlayerState

func enter() -> void:
	player.play_animation("player_down")

func physics_update(delta: float) -> void:
	if player.kick_started:
		player.change_state("kick")
		return

	player.move_horizontally(delta)
	if player.is_on_floor():
		player.change_state(player.get_ground_state())
