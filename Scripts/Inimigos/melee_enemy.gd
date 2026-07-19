extends BaseEnemy

const CONTACT_KNOCKBACK_MULTIPLIER: float = 0.9

func _ready() -> void:
	super() 
	
	max_health = 80 + ((Global.get_difficulty_index() - 1) * 50)
	current_health = max_health
	aparencia = $AnimatedAppearence
	set_meta("contact_knockback_multiplier", CONTACT_KNOCKBACK_MULTIPLIER)
	
func _physics_process(delta: float) -> void:
	super(delta)
	_play_pecado_animation()
