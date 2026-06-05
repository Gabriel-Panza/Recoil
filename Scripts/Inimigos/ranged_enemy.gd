extends BaseEnemy
class_name RangedEnemy

@export var projectile_scene: PackedScene = preload("res://Cenas/Inimigos/enemyProjectile.tscn")
@export var attack_range: float = 155.0
@export var stop_distance: float = 75.0
@export var fire_rate: float = 1.5

const RANGED_SPRITESHEET: String = "res://Sprites/demonho_ranged.png"
const RANGED_FRAME_SIZE: Vector2i = Vector2i(32, 32)
const RANGED_FRAMES_PER_ROW: int = 4
const RANGED_STATES: Array = ["walk", "charge", "shoot"]
const SHOOT_CHARGE_TIME: float = 0.24
const SHOOT_FLASH_TIME: float = 0.16

var fire_cooldown: float = 0.0
var is_shooting_animation: bool = false

func _ready() -> void:
	super()

	max_health = 50 + ((Global.pecado - 1) * 35)
	current_health = max_health
	_configure_enemy_sprite_sheet(RANGED_SPRITESHEET, RANGED_FRAME_SIZE, RANGED_FRAMES_PER_ROW, RANGED_STATES, {}, 8.0, Vector2(1.25, 1.25))
	_play_pecado_animation("walk")

func _physics_process(delta: float) -> void:
	super(delta)

	if player:
		handle_shooting(delta)
		_update_sprite_direction()
		if not is_shooting_animation:
			_play_pecado_animation("walk")

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
		if fire_cooldown > 0:
			fire_cooldown -= delta
		if fire_cooldown <= 0:
			shoot()
			fire_cooldown = fire_rate

func shoot() -> void:
	if is_shooting_animation or not projectile_scene:
		return

	is_shooting_animation = true
	_play_pecado_animation("charge")
	await get_tree().create_timer(SHOOT_CHARGE_TIME, false).timeout
	if not is_inside_tree() or player == null:
		is_shooting_animation = false
		return

	_fire_projectiles()
	_play_pecado_animation("shoot")
	await get_tree().create_timer(SHOOT_FLASH_TIME, false).timeout
	is_shooting_animation = false
	_play_pecado_animation("walk")

func _fire_projectiles() -> void:
	var projectile = projectile_scene.instantiate()
	projectile.global_position = global_position
	var aim_direction = global_position.direction_to(player.global_position)
	projectile.direction = aim_direction
	projectile.damage = damage * 1.25
	var tree = get_tree()
	var parent = tree.current_scene if tree != null and tree.current_scene else null
	if parent == null:
		projectile.queue_free()
		return

	parent.add_child(projectile)

func _update_sprite_direction() -> void:
	if aparencia and player:
		aparencia.flip_h = player.global_position.x < global_position.x

func _is_visible_on_screen() -> bool:
	var camera = get_viewport().get_camera_2d()
	if not camera:
		return true

	var cam_pos = camera.global_position
	var viewport_size = get_viewport_rect().size
	var cam_zoom = camera.zoom
	var real_view_size = viewport_size / cam_zoom

	var top_left = cam_pos - (real_view_size / 2)
	var bottom_right = cam_pos + (real_view_size / 2)
	var padding: float = 15.0

	var inside_x = global_position.x > (top_left.x + padding) and global_position.x < (bottom_right.x - padding)
	var inside_y = global_position.y > (top_left.y + padding) and global_position.y < (bottom_right.y - padding)

	return inside_x and inside_y
