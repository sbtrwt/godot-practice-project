extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.




func _on_button_play_pressed() -> void:
	$CanvasLayer/startScreen.visible = false
	$CanvasLayer/chooseScreen.visible = true


func _on_button_ship_one_pressed() -> void:
	Global.chosen_ship = 1
	$CanvasLayer/chooseScreen/ships/SpriteOne.visible = true
	$CanvasLayer/chooseScreen/ships/SpriteTwo.visible = false
	$CanvasLayer/chooseScreen/ships/SpriteThree.visible = false


func _on_button_ship_two_pressed() -> void:
	Global.chosen_ship = 2
	$CanvasLayer/chooseScreen/ships/SpriteOne.visible = false
	$CanvasLayer/chooseScreen/ships/SpriteTwo.visible = true
	$CanvasLayer/chooseScreen/ships/SpriteThree.visible = false


func _on_button_ship_three_pressed() -> void:
	Global.chosen_ship = 3
	$CanvasLayer/chooseScreen/ships/SpriteOne.visible = false
	$CanvasLayer/chooseScreen/ships/SpriteTwo.visible = false
	$CanvasLayer/chooseScreen/ships/SpriteThree.visible = true


func _on_button_choose_pressed() -> void:
	Global.game_on = true
	$CanvasLayer/chooseScreen.visible = false
	$CanvasLayer/inGameScreen.visible = true
	$CanvasLayer/chooseScreen.queue_free()


func _on_button_mute_pressed() -> void:
	if Global.mute == false:
		Global.mute = true
	$CanvasLayer/inGameScreen/ButtonMute/LabelOff.visible = !Global.mute
	$CanvasLayer/inGameScreen/ButtonMute/LabelOn.visible = Global.mute


func _on_button_menu_pressed() -> void:
	Global.reset_values()
	get_tree(). reload_current_scene()

func _process(delta):
	if Global.game_over == true:
		$CanvasLayer/inGameScreen.visible =false
		$CanvasLayer/gameOverScreen.visible = true
	$CanvasLayer/inGameScreen/LabelScore.text = str(Global.score)
	$CanvasLayer/gameOverScreen/LabelScore.text = str("Score: %d", Global.score)
