extends Node2D

@export var weapon_type = "pistol"

func _process(delta):
	if weapon_type == "pistol":
		$images/pistol.visible = true
		$images/silencer.visible = false
		$images/machine.visible = false
	elif weapon_type == "silencer":
		$images/pistol.visible = false
		$images/silencer.visible = true
		$images/machine.visible = false
	elif weapon_type == "machine":
		$images/pistol.visible = false
		$images/silencer.visible = false
		$images/machine.visible = true

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		if weapon_type == "pistol":
			Global.store_opened = "pistol"
		elif weapon_type == "silencer":
			Global.store_opened = "silencer"
		elif weapon_type == "machine":
			Global.store_opened = "machine"


func _on_area_2d_area_exited(area: Area2D) -> void:
	if area.is_in_group("player"):
		Global.store_opened = ""
