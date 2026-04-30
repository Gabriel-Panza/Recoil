extends BaseEnemy

func _ready() -> void:
	super() 
	
	max_health = 100
	current_health = max_health

func _physics_process(delta: float) -> void:
	super(delta)
	
	if Global.pecado == 1:
		$AparenciaAnimada.play("pecado1")
	elif Global.pecado == 2:
		$AparenciaAnimada.play("pecado2")
	elif Global.pecado == 3:
		$AparenciaAnimada.play("pecado3")
	elif Global.pecado == 4:
		$AparenciaAnimada.play("pecado4")
	elif Global.pecado == 5:
		$AparenciaAnimada.play("pecado5")
	elif Global.pecado == 6:
		$AparenciaAnimada.play("pecado6")
	elif Global.pecado == 7:
		$AparenciaAnimada.play("pecado7")
