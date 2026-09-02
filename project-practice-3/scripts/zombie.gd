extends CharacterBody2D

@onready var navigation_agent : NavigationAgent2D = $NavigationAgent2D
@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

const SPEED = 150.0
const ACCELERATION = 8.0
const MOVEMENT_THRESHOLD = 5.0
var velocity_smoothed : Vector2 = Vector2.ZERO
var player_node: Node2D = null

const STOP_DISTANCE = 30.0
const PATH_UPDATE_INTERVAL = 0.1
var path_update_timer: float = 0.0
var HEALTH: int = Global.zom_health

func _ready() -> void:
	await get_tree().create_timer(0.1).timeout
	var player = get_tree().get_nodes_in_group("player")
	if not player.is_empty():
		player_node = player[0]
		navigation_agent.target_position = player_node.global_position

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player_node):
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	var distance_to_player = global_position.distance_to(player_node.global_position)
	if distance_to_player <STOP_DISTANCE:
		var zero_velocity = Vector2.ZERO
		velocity_smoothed = velocity_smoothed.lerp(zero_velocity, ACCELERATION * delta)
		velocity = velocity_smoothed
		move_and_slide()
		return
	
	path_update_timer += delta
	if path_update_timer > PATH_UPDATE_INTERVAL:
		navigation_agent.target_position = player_node.global_position
		path_update_timer = 0.0
	
	var next_path_point: Vector2 = navigation_agent.get_next_path_position()
	var direction: Vector2 = global_position.direction_to(next_path_point).normalized()
	var desired_velocity: Vector2 = direction * SPEED
	
	velocity_smoothed = velocity_smoothed.lerp(desired_velocity, ACCELERATION * delta)
	velocity = velocity_smoothed
	move_and_slide()
	
	if velocity.length() > MOVEMENT_THRESHOLD:
		self.rotation = velocity.angle()
 


func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("bullet") or area.is_in_group("knife"):
		HEALTH -= 1
		Global.money += 1
		if area.is_in_group("bullet"):
			area.get_parent().queue_free()
		animation_player.play("hurting")
		if HEALTH <= 0:
			Global.money += 100
			Global.dead_zoms += 1
			queue_free()
		
