extends BaseEnemy
class_name TankEnemy

const TANK_SPRITESHEET: String = "res://Sprites/demonho_tank.png"
const TANK_FRAME_SIZE: Vector2i = Vector2i(48, 48)
const TANK_FRAMES_PER_ROW: int = 4
const CONTACT_KNOCKBACK_MULTIPLIER: float = 0.315
const TANK_ROW_BY_PECADO = {
	1: 4,
	2: 4,
	3: 5,
	4: 2,
	5: 3,
	6: 1,
	7: 0,
}

func _ready() -> void:
	super()

	max_health = 200 + ((Global.pecado - 1) * 100)
	current_health = max_health
	speed *= 0.8
	damage = 35
	set_meta("contact_knockback_multiplier", CONTACT_KNOCKBACK_MULTIPLIER)
	_configure_enemy_sprite_sheet(TANK_SPRITESHEET, TANK_FRAME_SIZE, TANK_FRAMES_PER_ROW, ["walk"], TANK_ROW_BY_PECADO, 5.5, Vector2(1.5, 1.5))
	_play_pecado_animation()

func mover(_delta: float) -> void:
	super(_delta)

	if aparencia and velocity.x != 0:
		aparencia.flip_h = velocity.x < 0

func _physics_process(delta: float) -> void:
	super(delta)
	_play_pecado_animation()
