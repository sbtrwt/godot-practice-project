extends Node2D

#remember to put correct level scenes
@onready var level_one = preload("res://scenes/main.tscn")
@onready var level_two = preload("res://scenes/main.tscn")
@onready var level_three = preload("res://scenes/main.tscn")

func _ready() -> void:
	$menu.visible = true
	$inGame.visible =false
	$gameOver.visible =false
	$gameWin.visible = false

func _process(delta: float) -> void:
	if Global.game_win == true:
		$menu.visible = false
		$inGame.visible =false
		$gameOver.visible =false
		$gameWin.visible = true
	if Global.game_over == true:
		$menu.visible = false
		$inGame.visible =false
		$gameOver.visible =true
		$gameWin.visible = false
	$inGame/textCount/Label.text = str(Global.coins)
	$gameWin/LabelCoins.text = str("Coins: ",Global.coins)
	update_current_hearts()
	
func update_current_hearts():
	if Global.health >= 3:
		Global.health = 3
		$inGame/hearts/normalHearts/h1.visible = true
		$inGame/hearts/normalHearts/h2.visible = true
		$inGame/hearts/normalHearts/h3.visible = true
	elif Global.health == 2:
		$inGame/hearts/normalHearts/h1.visible = true
		$inGame/hearts/normalHearts/h2.visible = true
		$inGame/hearts/normalHearts/h3.visible = false
	elif Global.health == 1:
		$inGame/hearts/normalHearts/h1.visible = true
		$inGame/hearts/normalHearts/h2.visible = false
		$inGame/hearts/normalHearts/h3.visible = false
	elif Global.health <= 0:
		$inGame/hearts/normalHearts/h1.visible = false
		$inGame/hearts/normalHearts/h2.visible = false
		$inGame/hearts/normalHearts/h3.visible = false
	
	if Global.active_power_up == true:
		$inGame/hearts/powerHearts.visible = true
	else:
		$inGame/hearts/powerHearts.visible = false


func _on_button_mute_pressed() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), true)


func _on_button_level_one_pressed() -> void:
	$menu.visible = false
	$inGame.visible = true
	var new_level = level_one.instantiate()
	add_sibling(new_level)


func _on_button_level_two_pressed() -> void:
	$menu.visible = false
	$inGame.visible = true
	var new_level = level_two.instantiate()
	add_sibling(new_level)


func _on_button_level_three_pressed() -> void:
	$menu.visible = false
	$inGame.visible = true
	var new_level = level_three.instantiate()
	add_sibling(new_level)


func _on_button_menu_pressed() -> void:
	Global.reset_values()
	get_tree().reload_current_scene()
