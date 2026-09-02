extends Node2D

func _process(delta: float) -> void:
	if Global.current_items[Global.current_slot][0] == "pistol" :
		$pistol . visible = true
		$silencer. visible = false
		$machine. visible = false
	elif Global.current_items[Global.current_slot][0] == "silencer" :
		$pistol . visible = false
		$silencer. visible = true
		$machine. visible = false
	elif Global.current_items[Global.current_slot][0] == "machine" :
		$pistol . visible = false
		$silencer. visible = false
		$machine. visible = true
	
	update_weapon_in_use()

func  update_weapon_in_use():
	if Input.is_key_pressed(KEY_1) and Global.current_items[0][0] != "":
		Global.current_slot = 0
	if Input.is_key_pressed(KEY_2) and Global.current_items[1][0] != "":
		Global.current_slot = 1
		
