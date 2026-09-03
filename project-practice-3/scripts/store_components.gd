extends Node2D

func _process(delta: float) -> void:
	if Global.store_opened == "pistol":
		$pistolStore.visible = true
		$silencerStore.visible = false
		$machineStore.visible = false
	elif Global.store_opened == "silencer":
		$pistolStore.visible = false
		$silencerStore.visible = true
		$machineStore.visible = false
	elif Global.store_opened == "machine":
		$pistolStore.visible = false
		$silencerStore.visible = false
		$machineStore.visible = true
	else:
		
		$pistolStore.visible = false
		$silencerStore.visible = false
		$machineStore.visible = false

func close_store():
	Global.store_opened =""



func _on_button_buy_gun_pressed() -> void:
	if Global.money < 1500:
		return
	if Global.current_items[1][0] == "":
		if Global.store_opened == "pistol":
			Global.current_items[1] = ["pistol", 12, 12, 120, 120]
		elif Global.store_opened == "silencer":
			Global.current_items[1] = ["silencer", 20, 20, 140, 140]
		elif Global.store_opened == "machine":
			Global.current_items[1] = ["machine", 40, 40, 200, 200]
	else:
		if Global.store_opened == "pistol":
			Global.current_items[Global.current_slot] = ["pistol", 12, 12, 120, 120]
		elif Global.store_opened == "silencer":
			Global.current_items[Global.current_slot] = ["silencer", 20, 20, 140, 140]
		elif Global.store_opened == "machine":
			Global.current_items[Global.current_slot] = ["machine", 40, 40, 200, 200]
	Global.money -= 1500
	close_store()

func _on_button_buy_ammo_pressed() -> void:
	if Global.current_items[0][0] == Global.store_opened:
		if Global.money >= 1000:
			Global.current_items[Global.current_slot][3] = Global.current_items[Global.current_slot][4]
			Global.money -= 1000
			print(Global.current_items)
			close_store()
	elif Global.current_items[1][0] == Global.store_opened:
		if Global.money >= 1000:
			Global.current_items[Global.current_slot][3]= Global.current_items[Global.current_slot][4]
			Global.money -= 1000
			close_store()
