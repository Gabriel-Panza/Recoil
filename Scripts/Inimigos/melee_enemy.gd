extends BaseEnemy

func _ready() -> void:
	super() 
	
	max_health = 100
	current_health = max_health
	aparencia = $AparenciaAnimada
	
func _physics_process(delta: float) -> void:
	super(delta)
	
	if Global.pecado == 1:
		aparencia.play("pecado1")
	elif Global.pecado == 2:
		aparencia.play("pecado2")
	elif Global.pecado == 3:
		aparencia.play("pecado3")
	elif Global.pecado == 4:
		aparencia.play("pecado4")
	elif Global.pecado == 5:
		aparencia.play("pecado5")
	elif Global.pecado == 6:
		aparencia.play("pecado6")
	elif Global.pecado == 7:
		aparencia.play("pecado7")
