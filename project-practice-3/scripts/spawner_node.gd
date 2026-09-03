extends Node2D

enum WaveState{
	START,
	CLEANUP,
	SPAWNING_WAVE
}

const BASE_ZOMBIES = 20
const WAVE_INCREMENT = 5
const BASE_SPAWN_RATE = 2.0
const SPAWN_RATE_DECREMENT = 0.1

var current_wave_state: WaveState = WaveState.START
var current_wave = Global.wave
var zombies_to_spawn : int = 0
var zombies_in_current_wave : int = 0
var zombies_points: Array[Node] =[] as Array[Node]

var added_right_points = false
var added_left_points = false
var added_top_points = false
var last_updated_areas: Array = []

@onready var basicZombie = preload("res://components/zombie.tscn")
@onready var spawn_timer: Timer = $TimerSpawn

func _ready() -> void:
	if current_wave == 0:
		current_wave = 1
		Global.dead_zoms = 0
	zombies_in_current_wave = 0
	update_current_zom_points()
	

func _process(delta):
	if last_updated_areas != Global.unlocked_areas:
		update_current_zom_points()
	if Global.game_on and current_wave_state == WaveState.START:
		start_wave_sequence()
		
	match current_wave_state:
		WaveState.CLEANUP:
			if not Global.game_on:
				return
			if Global.dead_zoms >=zombies_in_current_wave:
				Global.dead_zoms = 0
				start_wave_sequence()
			

func start_wave_sequence():
	if not Global.game_on:
		return
	
	var wave_number = current_wave
	zombies_to_spawn = BASE_ZOMBIES + (WAVE_INCREMENT * (wave_number - 1))
	zombies_in_current_wave = zombies_to_spawn
	
	var new_spawn_rate = BASE_SPAWN_RATE - (SPAWN_RATE_DECREMENT * (wave_number - 1))
	new_spawn_rate = max(0.5, new_spawn_rate)
	
	Global.wave = current_wave
	Global.zom_health += 1
	
	if is_instance_valid(spawn_timer):
		spawn_timer.wait_time = new_spawn_rate
		if Global.game_on:
			spawn_timer.start()
		
	current_wave_state = WaveState.SPAWNING_WAVE
	current_wave += 1
	

		


func _on_timer_spawn_timeout() -> void:
	if not Global.game_on:
		return
	
	if current_wave_state != WaveState.SPAWNING_WAVE:
		spawn_timer	.stop()
		return
	
	if zombies_to_spawn > 0:
		spawn_zombie()
		zombies_to_spawn -= 1
		
		if zombies_to_spawn <=0:
			spawn_timer.stop()
			current_wave_state = WaveState.CLEANUP
	else:
		spawn_timer.stop()
		current_wave_state = WaveState.CLEANUP
		
func spawn_zombie():
	var random_spot = zombies_points.pick_random() as Node2D
	var new_zombie = basicZombie.instantiate()
	new_zombie.global_position = random_spot.global_position
	get_tree().current_scene.add_child(new_zombie)

func update_current_zom_points():
	for area in Global.unlocked_areas:
		if area == "right" and added_right_points == false:
			added_right_points = true
			if is_instance_valid($zombiePoints/right/point8): $zombiePoints/right/point8.add_to_group("zomPoint")
			if is_instance_valid($zombiePoints/right/point9): $zombiePoints/right/point9.add_to_group("zomPoint")
			if is_instance_valid($zombiePoints/right/point10): $zombiePoints/right/point10.add_to_group("zomPoint")

		if area == "left" and added_left_points == false:
			added_left_points = true
			if is_instance_valid($zombiePoints/left/point5): $zombiePoints/left/point5.add_to_group("zomPoint")
			if is_instance_valid($zombiePoints/left/point6): $zombiePoints/left/point6.add_to_group("zomPoint")
			if is_instance_valid($zombiePoints/left/point7): $zombiePoints/left/point7.add_to_group("zomPoint")	
		if area == "top" and added_top_points == false:
			added_top_points = true
			if is_instance_valid($zombiePoints/top/point11): $zombiePoints/top/point11.add_to_group("zomPoint")
			if is_instance_valid($zombiePoints/top/point12): $zombiePoints/top/point12.add_to_group("zomPoint")
			if is_instance_valid($zombiePoints/top/point13): $zombiePoints/top/point13.add_to_group("zomPoint")	
			if is_instance_valid($zombiePoints/top/point14): $zombiePoints/top/point14.add_to_group("zomPoint")	
	zombies_points = get_tree(). get_nodes_in_group("zomPoint") as Array[Node]
	last_updated_areas = Global.unlocked_areas.duplicate()
