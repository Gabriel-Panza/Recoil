extends BaseEnemy 
class_name RangedEnemy

@export var projectile_scene: PackedScene = preload("res://Cenas/Inimigos/enemyProjectile.tscn")
@export var attack_range: float = 225.0  
@export var stop_distance: float = 125.0 
@export var fire_rate: float = 2.5

var fire_cooldown: float = 0.0

func _ready() -> void:
	super() 
	
	max_health = 50
	current_health = max_health

func _physics_process(delta: float) -> void:
	super(delta)
	
	if player:
		handle_shooting(delta)

func mover(_delta: float) -> void:
	var distance_to_player = global_position.distance_to(player.global_position)
	
	if distance_to_player > attack_range:
		var direction = global_position.direction_to(player.global_position)
		velocity = direction * speed * _delta
	elif distance_to_player < stop_distance:
		var direction = global_position.direction_to(-player.global_position)
		velocity = direction * speed * _delta
	else:
		velocity = Vector2.ZERO
		
	move_and_slide()

func handle_shooting(delta: float) -> void:
	var distance_to_player = global_position.distance_to(player.global_position)
	
	if fire_cooldown > 0:
		fire_cooldown -= delta
		
	if distance_to_player <= attack_range and distance_to_player >= stop_distance and fire_cooldown <= 0:
		shoot()
		fire_cooldown = fire_rate

func shoot() -> void:
	if not projectile_scene:
		return
		
	var projectile = projectile_scene.instantiate()
	projectile.global_position = global_position
	var aim_direction = global_position.direction_to(player.global_position)
	projectile.direction = aim_direction
	projectile.damage = damage*1.25
	get_tree().current_scene.add_child(projectile)
