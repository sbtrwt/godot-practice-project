class_name MovementCommand
extends PlayerCommand

var direction: float
var down_pressed: bool

func _init(movement_direction: float, is_down_pressed: bool) -> void:
	direction = movement_direction
	down_pressed = is_down_pressed

func execute(player: CharacterBody2D) -> void:
	player.set_replay_input(direction, down_pressed)