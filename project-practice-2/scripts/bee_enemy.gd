extends CharacterBody2D

@export var speed: float = 150.0
@export var health : int =1
@export var gravity: float = 1900.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area : Area2D = $Area2DDetection

var is_dead: bool = false
var player_in_range: bool = false
var player: CharacterBody2D

func _ready() -> void:
	$AnimatedSprite2D.play("default")
	
func _physics_process(delta: float) -> void:
	if not is_dead:
		handle_movement()
	else:
		velocity.y+= gravity * delta
	move_and_slide()
	
func _process(delta: float) -> void:
	if Global.game_win == true:
		die()



func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("feet"):
		handle_damage(area.get_parent().get_parent())
		area.get_parent().get_parent().player_jump()


func _on_area_2d_detection_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		player = body


func _on_area_2d_detection_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		player = null

func handle_movement():
	if player_in_range == true and player:
		var target_position : Vector2 = player.global_position
		var direction: Vector2 = (target_position - global_position).normalized()
		velocity = direction * speed
		sprite.flip_h = velocity.x  > 0
	
	else:
		velocity = Vector2.ZERO

func handle_damage(damage: CharacterBody2D):
	if is_dead:
		return
	damage.velocity.y = damage.jump_velocity
	health -= 1
	if health <= 0:
		die()

func die():
	if is_dead :
		return
	is_dead = true
	call_deferred("_disabled_collisions")
	var death_tween = create_tween()
	death_tween.tween_property(self, "rotation",deg_to_rad(360 * 10), 3.0).set_ease(Tween.EASE_OUT)
	death_tween.tween_callback(queue_free).set_delay(2.0)

func _disabled_collisions():
	for child in get_children():
		if child is CollisionShape2D:
			child.disabled = true
		
