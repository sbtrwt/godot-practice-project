class_name PlayerState
extends RefCounted

var player: CharacterBody2D

func _init(owner: CharacterBody2D) -> void:
	player = owner

func enter() -> void:
	pass

func update(_delta: float) -> void:
	pass

func physics_update(_delta: float) -> void:
	pass

func exit() -> void:
	pass
