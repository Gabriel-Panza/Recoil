extends BaseEnemy
class_name TankEnemy

func _ready() -> void:
	super()
	
	# Status massivos (Escala bem com o nível de Pecado)
	max_health = 200.0 + ((Global.pecado - 1) * 100.0)
	current_health = max_health
	aparencia = $AnimatedAppearence
	
	# Status de movimentação e ataque do colosso
	speed = 90.0
	damage = 35.0   

func mover(_delta: float) -> void:
	# Usa a movimentação padrão herdada 
	super(_delta)
	
	# Inverte o sprite para olhar pro player baseado no movimento
	if aparencia and velocity.x != 0:
		aparencia.flip_h = velocity.x < 0

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
