extends RangedEnemy
class_name SpreadEnemy

@export var bullets_per_shot: int = 5
@export var spread_angle: float = 10.0

func _ready() -> void:
	super()

	max_health = 75 + ((Global.pecado - 1) * 25)
	current_health = max_health

func shoot() -> void:
	if not projectile_scene:
		return
		
	var base_direction = global_position.direction_to(player.global_position)
	var base_angle = base_direction.angle()
	
	for i in range(bullets_per_shot):
		var projectile = projectile_scene.instantiate()
		projectile.global_position = global_position
		
		# Calcula o desvio de ângulo para cada bala do cone
		var angle_offset = deg_to_rad((i - (bullets_per_shot - 1) / 2.0) * spread_angle)
		var final_angle = base_angle + angle_offset
		
		projectile.direction = Vector2(cos(final_angle), sin(final_angle))
		projectile.damage = damage * 0.8 # Cada bala individual dá um pouco menos de dano
		
		get_tree().current_scene.add_child(projectile)
