class_name PunchCommand
extends PlayerCommand

func execute(player: CharacterBody2D) -> void:
	player.change_state("punch")