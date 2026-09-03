extends Node2D


func _ready():
	$menu.visible = true
	$inGame.visible  = false
	

func _process(delta: float) -> void:
	if Global.store_opened == "":
		$store.visible = false
	elif Global.store_opened != "":
		$store.visible = true
	
	if Global.game_over == true:
		$gameOver.visible = true



func _on_button_menu_pressed() -> void:
	Global._reset_game_values()
	get_tree().reload_current_scene()
	


func _on_button_pressed() -> void:
	Global.game_on = true
	$menu.visible = false
	$inGame.visible = true
