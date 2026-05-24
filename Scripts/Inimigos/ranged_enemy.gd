extends BaseEnemy 
class_name RangedEnemy

@export var projectile_scene: PackedScene = preload("res://Cenas/Inimigos/enemyProjectile.tscn")
@export var attack_range: float = 200.0  
@export var stop_distance: float = 40.0 
@export var fire_rate: float = 1.5

var fire_cooldown: float = 0.0

func _ready() -> void:
	super() 
	
	max_health = 50 + ((Global.pecado - 1) * 35)
	current_health = max_health

func _physics_process(delta: float) -> void:
	super(delta)
	
	if player:
		handle_shooting(delta)

func mover(_delta: float) -> void:
	var distance_to_player = global_position.distance_to(player.global_position)
	
	if distance_to_player > attack_range:
		var direction = global_position.direction_to(player.global_position)
		velocity = direction * speed
	elif distance_to_player < stop_distance:
		var direction = player.global_position.direction_to(global_position)
		velocity = direction * speed
	else:
		velocity = Vector2.ZERO
		
	move_and_slide()

func handle_shooting(delta: float) -> void:
	var distance_to_player = global_position.distance_to(player.global_position)
	
	if distance_to_player <= attack_range and distance_to_player >= stop_distance:
	
		if _is_visible_on_screen():
			if fire_cooldown > 0:
				fire_cooldown -= delta
			if fire_cooldown <= 0:
				shoot()
				fire_cooldown = fire_rate
		else:
			# Se ele sair da tela, o cooldown reseta para ele não "acumular" um tiro para dar na bordinha
			fire_cooldown = 0.0

func shoot() -> void:
	if not projectile_scene:
		return
		
	var projectile = projectile_scene.instantiate()
	projectile.global_position = global_position
	var aim_direction = global_position.direction_to(player.global_position)
	projectile.direction = aim_direction
	projectile.damage = damage*1.25
	get_tree().current_scene.add_child(projectile)

# >>> SUBSTITUA A FUNÇÃO INTEIRA NO FINAL DO SEU RANGED_ENEMY.GD POR ESTA:
func _is_visible_on_screen() -> bool:
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return true
		
	var cam_pos = camera.global_position
	var viewport_size = get_viewport_rect().size
	
	# >>> AQUI ESTÁ O SEGREDO: Divide o tamanho da janela pelo ZOOM real da câmera
	# Se a sua janela é 1152 e o zoom é 3x, a área visível real é de apenas 384 pixels!
	var cam_zoom = camera.zoom
	var real_view_size = viewport_size / cam_zoom
	
	# Calcula as bordas exatas daquele quadrado rosa no seu mapa global
	var top_left = cam_pos - (real_view_size / 2)
	var bottom_right = cam_pos + (real_view_size / 2)
	
	# Margem de segurança de 25 pixels para o inimigo ter que botar o corpo bem para dentro do rosa
	var padding: float = 15.0
	
	var dentro_x = global_position.x > (top_left.x + padding) and global_position.x < (bottom_right.x - padding)
	var dentro_y = global_position.y > (top_left.y + padding) and global_position.y < (bottom_right.y - padding)
	
	return dentro_x and dentro_y
