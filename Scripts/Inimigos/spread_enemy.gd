extends RangedEnemy
class_name SpreadEnemy

@export var bullets_per_shot: int = 5
@export var spread_angle: float = 12.0

const SPREAD_SPRITESHEET: String = "res://Sprites/demonho_spread.png"
const SPREAD_FRAME_SIZE: Vector2i = Vector2i(36, 36)
const SPREAD_FRAMES_PER_ROW: int = 4
const SPREAD_STATES: Array = ["walk", "charge", "shoot"]

func _ready() -> void:
	super()

	max_health = 80 + ((Global.get_difficulty_index() - 1) * 25)
	current_health = max_health
	_configure_enemy_sprite_sheet(SPREAD_SPRITESHEET, SPREAD_FRAME_SIZE, SPREAD_FRAMES_PER_ROW, SPREAD_STATES, {}, 7.0, Vector2(1.18, 1.18))
	_play_pecado_animation("walk")

func _fire_projectiles() -> void:
	if not projectile_scene or player == null:
		return

	var base_direction = global_position.direction_to(player.global_position)
	var base_angle = base_direction.angle()

	for i in range(bullets_per_shot):
		var projectile = projectile_scene.instantiate()
		projectile.global_position = global_position

		var angle_offset = deg_to_rad((i - (bullets_per_shot - 1) / 2.0) * spread_angle)
		var final_angle = base_angle + angle_offset

		projectile.direction = Vector2(cos(final_angle), sin(final_angle))
		projectile.damage = damage * 0.8
		projectile.set_meta("damage_source", self)

		var tree = get_tree()
		var parent = tree.current_scene if tree != null and tree.current_scene else null
		if parent == null:
			projectile.queue_free()
			continue

		parent.add_child(projectile)
