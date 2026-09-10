class_name JumpCommand
extends PlayerCommand

func execute(player: CharacterBody2D) -> void:
	player.player_jump()