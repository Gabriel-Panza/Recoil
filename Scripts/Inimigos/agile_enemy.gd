extends BaseEnemy
class_name AgileEnemy

@export var orbit_distance: float = 150.0
@export var dash_speed: float = 450.0
@export var time_to_dash: float = 3.5 
@export var dash_duration: float = 0.75 

const AGILE_SPRITESHEET: String = "res://Sprites/demonho_agile.png"
const AGILE_FRAME_SIZE: Vector2i = Vector2i(26, 21)
const AGILE_FRAMES_PER_ROW: int = 1
const AGILE_FRAME_SPACING: Vector2i = Vector2i(0, 1)

var state_timer: float = 0.0
var is_dashing: bool = false
var dash_direction: Vector2 = Vector2.ZERO
var orbit_direction: int = 1

var bump_cooldown: float = 0.0

func _ready() -> void:
	super()
	add_to_group(AGILE_COLLISION_BYPASS_GROUP)
	collision_layer = collision_layer & ~Global.ENEMY_LAYER_MASK
	collision_mask = collision_mask & ~Global.ENEMY_COLLISION_MASK
	orbit_direction = 1 if randf() > 0.5 else -1
	
	max_health = 50 + ((Global.pecado - 1) * 30)
	current_health = max_health
	speed *= 1.67
	_configure_enemy_sprite_sheet(AGILE_SPRITESHEET, AGILE_FRAME_SIZE, AGILE_FRAMES_PER_ROW, ["walk"], {}, 6.0, Vector2(1.45, 1.45), AGILE_FRAME_SPACING)
	_play_pecado_animation()

func mover(_delta: float) -> void:
	var dir_to_player = global_position.direction_to(player.global_position)
	
	if bump_cooldown > 0:
		bump_cooldown -= _delta
	
	if is_dashing:
		# Estado de ataque (dash).
		velocity = dash_direction * dash_speed
		state_timer -= _delta
		
		# Verifica impacto.
		if state_timer <= 0 or get_slide_collision_count() > 0:
			is_dashing = false
			state_timer = 0.0
			velocity = -dash_direction * (dash_speed * 0.6)
	else:
		# Estado de orbita.
		state_timer += _delta
		var dist_to_player = global_position.distance_to(player.global_position)
		
		# Inverte a orbita quando encosta na parede durante o rodeio.
		if get_slide_collision_count() > 0 and bump_cooldown <= 0:
			orbit_direction *= -1
			bump_cooldown = 0.5
		
		# Calcula o vetor perpendicular para fazer a curva.
		var tangent = dir_to_player.rotated(PI/2 * orbit_direction)
		
		# Ajusta a distancia para manter a orbita.
		var distance_correction = 0.0
		if dist_to_player > orbit_distance + 20:
			distance_correction = 1.0
		elif dist_to_player < orbit_distance - 20:
			distance_correction = -1.0
			
		var move_dir = (tangent + (dir_to_player * distance_correction)).normalized()
		velocity = _get_obstacle_aware_velocity(move_dir, speed, _delta)
		
		# Prepara o dash.
		if state_timer >= time_to_dash:
			is_dashing = true
			state_timer = dash_duration
			dash_direction = dir_to_player

	# Espelha o sprite pela direcao atual.
	if aparencia and velocity.x != 0:
		aparencia.flip_h = velocity.x < 0
		
	move_and_slide()
