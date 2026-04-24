extends BaseEnemy

func _ready() -> void:
	super() 
	
	max_health = 50
	speed = 200.0
	current_health = max_health
