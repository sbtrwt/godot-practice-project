extends CharacterBody2D

@export var speed: float = 400.0
@onready var idle_sprite = $body/idle
@onready var attack_sprites = $body/attackSprites
@onready var knife_sprite = $body/knife
@onready var muzzle = $aim

@onready var shoot_controller  = $shootController

@onready var reload_timer = $TimerReload
@onready var knife_attack_timer = $TimerKnifeAttack
@onready var hurting_anim = $AnimationPlayer
@onready var hurting_timer = $TimerHurting
@onready var hit_box_area = $Area2D

@onready var camera_shaker = $Camera2D

const ZOMBIE_DAMAGE : int = 30
const HURT_COOLDOWN: float = 2.0
var is_invunnerable : bool = false

func _ready() -> void: 
	add_to_group("player")
	reload_timer.wait_time = Global. reload_time
	reload_timer.one_shot = true
	knife_attack_timer.one_shot = true
	knife_attack_timer.one_shot = true
	hurting_timer.wait_time = HURT_COOLDOWN
	hurting_timer.one_shot = true
	
func _physics_process(delta: float) -> void:
	if Global.game_over == true or Global.game_on == false:
		return
	rotate_towards_mouse()
	
	var input_vector = get_input_vector()
	velocity  = input_vector * speed
	move_and_slide()
	
	#shoot_controller.process_controller(delta)
	handle_sprite_state()
	
func rotate_towards_mouse() -> void:
	var mouse_position = get_global_mouse_position()
	look_at(mouse_position)

func get_input_vector() -> Vector2:
	var direction = Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		direction.x += 1
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1
	if Input.is_action_pressed("ui_down"):
		direction.y += 1
	if Input.is_action_pressed("ui_up"):
		direction.y -= 1
	return direction.normalized()
	
func handle_sprite_state():
	var is_knife_attacking = false #shoot_controller.is_knife_attacking
	
	var is_reloading = !reload_timer.is_stopped()
	var is_shooting = Input.is_action_pressed("left_click")
	
	if is_knife_attacking == true:
		attack_sprites.visible = false
		knife_sprite.visible = true
		idle_sprite.visible = false 
	elif is_shooting == true or is_reloading == true:
		attack_sprites.visible = true
		knife_sprite.visible = false
		idle_sprite.visible = false 
	else:
		attack_sprites.visible = false
		knife_sprite.visible = false
		idle_sprite.visible = true 
func cancel_reload():
	if not reload_timer.is_stopped():
		reload_timer.stop()

func take_damage(damage:int)-> void:
	if is_invunnerable == true:
		return
		
	Global.player_health -= damage
	is_invunnerable = true
	hurting_anim.play("hurting")
	$sounds/hurt.play()
	hurting_timer.start()
	

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("zombie") and not is_invunnerable and Global.game_over == false:
		if camera_shaker:
			camera_shaker.start_shake(8.0,0.2)
		if Global.player_health <= 0:
			Global.game_over = true
			return
		take_damage(ZOMBIE_DAMAGE)
	
			


func _on_timer_hurting_timeout() -> void:
	if Global.game_over == true:
		return
	
	is_invunnerable = false
	hurting_anim.play("idle")
	
	var overlapping_areas = hit_box_area.get_overlapping_areas()
	
	for area in overlapping_areas:
		if area.is_in_group("zombie"):
			if camera_shaker: 
				camera_shaker.start_shake(10.0, 0.1)
			take_damage(ZOMBIE_DAMAGE)
			return
			
