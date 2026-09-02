extends Node2D

var health = 10.0
var max_health = 10.0
var fixing = false
var zombie_in_area = false
const DAMAGE_RATE  = 1.5

@onready var door_block = $collisions/StaticBody2DDoor/CollisionShape2D
@onready var health_bar = $ProgressBar

@onready var fixing_timer = $TimerFixing

func _process(delta):
	if health <= 0:
		door_block.disabled = true
		$bg/boards.visible =false
	else:
		door_block.disabled = false
		$bg/boards.visible =true
	
	if zombie_in_area and health > 0:
		health -=  DAMAGE_RATE * delta
		health = max(health , 0.0)
		
	health_bar.value = health

func _on_timer_fixing_timeout():
	if health < max_health:
		Global.money += 10
		health += 3.0
		health = min(health, max_health)




func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		fixing = true
		fixing_timer.start()
	if area.is_in_group("zombie"):
		zombie_in_area = true
	


func _on_area_2d_area_exited(area: Area2D) -> void:
	if area.is_in_group("player"):
		fixing = false
		fixing_timer.stop()
	if area.is_in_group("zombie"):
		zombie_in_area = false
