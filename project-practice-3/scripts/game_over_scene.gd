extends Node2D

var game_ended = false

func _process(delta: float) -> void:
	if Global.game_over == true and game_ended == false:
		game_ended = true
		$AnimationPlayer.play("gameOver")
