extends BaseEnemy
class_name AgileEnemy

@export var orbit_distance: float = 150.0
@export var orbit_speed: float = 200.0
@export var dash_speed: float = 450.0
@export var time_to_dash: float = 3.5 
@export var dash_duration: float = 0.75 

var state_timer: float = 0.0
var is_dashing: bool = false
var dash_direction: Vector2 = Vector2.ZERO
var orbit_direction: int = 1

var bump_cooldown: float = 0.0

func _ready() -> void:
	super()
	orbit_direction = 1 if randf() > 0.5 else -1
	
	max_health = 50 + ((Global.pecado - 1) * 25)
	current_health = max_health
	speed = orbit_speed

func mover(_delta: float) -> void:
	var dir_to_player = global_position.direction_to(player.global_position)
	
	if bump_cooldown > 0:
		bump_cooldown -= _delta
	
	if is_dashing:
		# Estado de Ataque (Dash)
		velocity = dash_direction * dash_speed
		state_timer -= _delta
		
		# Verifica impacto
		if state_timer <= 0 or get_slide_collision_count() > 0:
			is_dashing = false
			state_timer = 0.0
			velocity = -dash_direction * (dash_speed * 0.6)
	else:
		# Estado de Órbita (Rodeando)
		state_timer += _delta
		var dist_to_player = global_position.distance_to(player.global_position)
		
		# >>> ALTERAÇÃO AQUI: Se bateu na quina enquanto tenta rodear, dá meia volta!
		if get_slide_collision_count() > 0 and bump_cooldown <= 0:
			orbit_direction *= -1
			bump_cooldown = 0.5 # Fica meio segundo sem poder virar de novo para escapar da parede
		
		# Calcula o vetor perpendicular para fazer a curva
		var tangent = dir_to_player.rotated(PI/2 * orbit_direction)
		
		# Ajuste para manter a distância ideal
		var distance_correction = 0.0
		if dist_to_player > orbit_distance + 20:
			distance_correction = 1.0 # Se afastou, puxa pra perto
		elif dist_to_player < orbit_distance - 20:
			distance_correction = -1.0 # Se aproximou, joga pra longe
			
		var move_dir = (tangent + (dir_to_player * distance_correction)).normalized()
		velocity = move_dir * speed
		
		# Hora do bote!
		if state_timer >= time_to_dash:
			is_dashing = true
			state_timer = dash_duration
			dash_direction = dir_to_player # Trava a mira na direção atual do player

	# Espelha o sprite baseado para onde ele está indo
	if aparencia and velocity.x != 0:
		aparencia.flip_h = velocity.x < 0
		
	move_and_slide()
