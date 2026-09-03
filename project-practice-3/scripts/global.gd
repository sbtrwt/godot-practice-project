extends Node


const MAGZINE_SIZE = 1
const BULLETS_IN_CLIP = 2
const AMMO_RESERVE = 3
var  SHOT_DELAY = 0.3

var game_on = true
var game_over = false
var player_health = 90.0
var store_opened = ""

var reloading = false

var current_items = [
	["pistol", 12, 12, 120, 120],
	["", 0,0,0,0]
]
var current_slot: int = 0
var reload_time: float = 2.0
var bullet_speed: float = 1400.0
var money :int =5000

var unlocked_areas = ["bottom"]
var wave =1
var zom_health = 0
var dead_zoms =0

func _process(delta: float) -> void:
	if current_items[current_slot][0] == "pistol":
		SHOT_DELAY = 0.3
		reload_time = 1.0
	elif current_items[current_slot][0] == "silencer":
		SHOT_DELAY = 0.2
		reload_time = 0.5
	elif current_items[current_slot][0] == "machine":
		SHOT_DELAY = 0.1
		reload_time = 2.0

func _reset_game_values():
	game_on = false
	game_over = false
	money = 500
	player_health = 90.0
	store_opened = ""
	current_slot = 0
	reloading = false
	unlocked_areas = ["bottom"]
	wave = 1
	zom_health = 0
	dead_zoms = 0
	current_items =  [
	["pistol", 12, 12, 120, 120],
	["", 0,0,0,0]
	]

func get_current_weapon_stats() -> Array:
	return current_items[current_slot]

func get_current_bullets() -> int:
	return current_items[current_slot][BULLETS_IN_CLIP]

func get_max_clip_size() -> int:
	return current_items[current_slot][MAGZINE_SIZE]

func get_reserve_ammo() -> int:
	return current_items[current_slot][AMMO_RESERVE]
