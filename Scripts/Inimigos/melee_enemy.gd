extends BaseEnemy

func _ready() -> void:
	super() 
	
	max_health = 100 + ((Global.pecado - 1) * 50)
	current_health = max_health
	aparencia = $AnimatedAppearence
	
func _physics_process(delta: float) -> void:
	super(delta)
	_play_pecado_animation()
