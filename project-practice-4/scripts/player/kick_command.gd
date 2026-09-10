class_name KickCommand
extends PlayerCommand

func execute(player: CharacterBody2D) -> void:
	player.change_state("kick")