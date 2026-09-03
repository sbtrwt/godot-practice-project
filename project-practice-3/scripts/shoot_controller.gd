extends Node2D


@export var KNIFE_ATTACK_DURATION: float  = 0.2
@export var KNIFE_COOLDOWN_TIME : float = 0.2

@onready var player : CharacterBody2D = get_parent()
@onready var muzzle : Node2D = $"../aim"
@onready var reload_timer: Timer = $"../TimerReload"

@onready var knife_attack_timer: Timer = $"../TimerKnifeAttack"
@onready var knife_area: CollisionShape2D = $"../body/knife/Area2D/CollisionShape2D"

const BULLET_SCENE = preload("res://components/bullet.tscn")

var can_fire : bool = true
var shot_cooldown: float = 0.0
var is_knife_attacking: bool = false
var ignore_next_shot_press: bool =false
var is_knife_on_cooldown: bool =false

func process_controller(delta: float) -> void:
	if shot_cooldown > 0:
		shot_cooldown -= delta
		if shot_cooldown <= 0:
			can_fire = true
	handle_shooting()
	handle_knife_attack()
	handle_reload_interrupt()

func cancel_reload_and_state()-> void:
	if not reload_timer.is_stopped():
		reload_timer.stop()
		Global.reloading = false
		can_fire = true
		print("timer realiding cancel")

func handle_reload_interrupt() -> void:
	if not reload_timer.is_stopped() and Input.is_action_just_released("left_click"):
		Global.reloading = false
		reload_timer.stop()
		print("reloading timer stopped..")
		can_fire = true

func handle_shooting() -> void:
	if Global.store_opened != "":
		return
	if ignore_next_shot_press and Input.is_action_just_pressed("left_click"):
		ignore_next_shot_press = false
		return
	if is_knife_attacking:
		return
	
	if Input.is_action_just_pressed("left_click") and can_fire and Global.get_current_bullets() > 0:
		fire_shot()
	if Input.is_action_just_pressed("left_click") and Global.get_current_bullets() == 0 and Global.get_reserve_ammo() > 0 and reload_timer.is_stopped():
		start_reload()
	
func handle_knife_attack() -> void:
	var is_idel_state = (
		!Input.is_action_just_pressed("left_click") and reload_timer.is_stopped()
	)
	
	if Input.is_action_just_pressed("ui_accept"):
		if not reload_timer.is_stopped():
			cancel_reload_and_state()
		if is_idel_state and !is_knife_attacking and !is_knife_on_cooldown:
			is_knife_attacking = true
			knife_area.disabled = false
			knife_attack_timer.wait_time = KNIFE_ATTACK_DURATION
			knife_attack_timer.start()
			$"../sounds/knife".play()
			can_fire = false
			shot_cooldown = 0.0
			ignore_next_shot_press
			
func fire_shot() -> void:
	can_fire = false
	$"../sounds/shoot".play()
	shot_cooldown = Global.SHOT_DELAY
	
	var bullet = BULLET_SCENE.instantiate()
	bullet.global_position = muzzle.global_position
	bullet.global_rotation = player.rotation
	var bullet_direction = Vector2.from_angle(player.rotation)
	var launch_vector = bullet_direction * Global.bullet_speed
	
	bullet.initialize_launch(launch_vector)
	player.get_parent().add_child(bullet)
	
	Global.current_items[Global.current_slot][Global.BULLETS_IN_CLIP] -= 1
	
	if Global.get_current_bullets() == 0:
		start_reload()
	
func start_reload() -> void:
	if Global.get_reserve_ammo() > 0 :
		Global.reloading = true
		can_fire = false
		print("timer reloading start")
		reload_timer.start()
		

func _on_timer_reload_timeout() -> void:
	print("reloading timeout")
	var max_clip = Global.get_max_clip_size()
	var reserve_ammo = Global.get_reserve_ammo()
	var current_clip = Global.get_current_bullets()
	var needed_bullets = max_clip - current_clip
	var bullets_to_take = min(needed_bullets, reserve_ammo)
	
	Global.current_items[Global.current_slot][Global.BULLETS_IN_CLIP] += bullets_to_take
	Global.current_items[Global.current_slot][Global.AMMO_RESERVE] -= bullets_to_take

	print(Global.current_items)
	can_fire =true
	Global.reloading = false



func _on_timer_knife_attack_timeout() -> void:
	print("knife attack timeout")
	if is_knife_attacking:
		is_knife_attacking = false
		is_knife_on_cooldown  = true
		knife_area.disabled = true
		knife_attack_timer.wait_time = KNIFE_COOLDOWN_TIME
		knife_attack_timer.start()
		
		if Input.is_action_pressed("left_click"):
			ignore_next_shot_press = true
			
		can_fire = true
	elif is_knife_on_cooldown:
		is_knife_on_cooldown = false
		
