extends Node2D

@onready var health_bar = $healthBar
@onready var ammo_label = $ammotext/LabelAmmo
@onready var money_text = $LabelMoney

func _process(delta: float) -> void:
	if Global.game_over == true:
		return
	update_gun_name()
	update_reloading_text()
	
	var current_clip_value: int = Global.current_items[Global.current_slot][2]
	var current_ammo_value: int = Global.current_items[Global.current_slot][3]
	var current_clip = str("%02d" % current_clip_value)
	var current_ammo = str("%03d" % current_ammo_value)
	
	ammo_label.text = current_clip + " / " + current_ammo
	money_text.text = "$" + str("%06d" % Global.money)
	
	if Global.player_health < 90:
		Global.player_health += 3 * delta
		Global.player_health = min (Global.player_health, 90.0)
	
	if Global.player_health <= 0:
		Global.game_over = true
		
	health_bar.value = Global.player_health
	$LabelWaves.text = "Wave " + str(Global.wave)

func update_gun_name():
	if Global.current_items[Global.current_slot][0] == "pistol":
		$gunName/LabelPistol.visible = true
		$gunName/LabelSilencer.visible = false
		$gunName/LabelMachine.visible = false
	elif Global.current_items[Global.current_slot][0] == "silencer":
		$gunName/LabelPistol.visible = false
		$gunName/LabelSilencer.visible = true
		$gunName/LabelMachine.visible = false
	elif Global.current_items[Global.current_slot][0] == "machine":
		$gunName/LabelPistol.visible = false
		$gunName/LabelSilencer.visible = false
		$gunName/LabelMachine.visible = true

func update_reloading_text():
	if Global.reloading == true:
		$ammotext/LabelReloading.visible = true
		$ammotext/LabelAmmo.visible =false 
	else:
		$ammotext/LabelReloading.visible = false
		$ammotext/LabelAmmo.visible =true 	
