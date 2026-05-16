extends CharacterBody2D
class_name Boss

enum BossState { SLOTH, GLUTTONY, ENVY, WRATH, LUST, GREED, PRIDE }
enum SlothSubState { IDLE, PREPARE, ATTACK, SPECIAL }
enum GluttonySubState { IDLE, PREPARE, ATTACK, SPECIAL }
enum EnvySubState { IDLE, PREPARE, ATTACK, SPECIAL }
enum WrathSubState { IDLE, PREPARE, ATTACK, SPECIAL }
enum LustSubState { IDLE, PREPARE, ATTACK, SPECIAL }
enum GreedSubState { IDLE, PREPARE, ATTACK, SPECIAL }
enum PrideSubState { IDLE, PREPARE, ATTACK, SPECIAL }

@export var max_health: int = 500
@export var speed: float = 5000.0
@export var damage: int = 50
@export var xp_drop: int = 1

var current_health: int
var player: Node2D
var aparencia

var current_state: BossState
var current_sub_state = null

func _ready() -> void:
	player = get_tree().get_first_node_in_group("Player")
	add_to_group("Boss")
	add_to_group("Enemy")
	aparencia = $AparenciaAnimada

	# Define o estado baseado no pecado atual
	match Global.pecado:
		7:
			max_health = 1250
			current_state = BossState.PRIDE
			current_sub_state = PrideSubState.IDLE
		6:
			max_health = 1125
			current_state = BossState.GREED
			current_sub_state = GreedSubState.IDLE
		5:
			max_health = 1000
			current_state = BossState.LUST
			current_sub_state = LustSubState.IDLE
		4:
			max_health = 875
			current_state = BossState.WRATH
			current_sub_state = WrathSubState.IDLE
		3:
			max_health = 750
			current_state = BossState.ENVY
			current_sub_state = EnvySubState.IDLE
		2:
			max_health = 625
			current_state = BossState.GLUTTONY
			current_sub_state = GluttonySubState.IDLE
		1:
			max_health = 500
			current_state = BossState.SLOTH
			current_sub_state = SlothSubState.IDLE
		_:
			max_health = 1250
			current_state = BossState.PRIDE
			current_sub_state = PrideSubState.IDLE
	current_health = max_health

func _physics_process(delta: float) -> void:
	if player:
		match current_state:
			BossState.PRIDE:
				aparencia.play("pecado7")
				handle_pride(delta)
			BossState.GREED:
				aparencia.play("pecado6")
				handle_greed(delta)
			BossState.LUST:
				aparencia.play("pecado5")
				handle_lust(delta)
			BossState.WRATH:
				aparencia.play("pecado4")
				handle_wrath(delta)
			BossState.ENVY:
				aparencia.play("pecado3")
				handle_envy(delta)
			BossState.GLUTTONY:
				aparencia.play("pecado2")
				handle_gluttony(delta)
			BossState.SLOTH:
				aparencia.play("pecado1")
				handle_sloth(delta)

func handle_pride(delta: float):
	match current_sub_state:
		PrideSubState.IDLE:
			# Lógica para Pride idle
			pass
		PrideSubState.PREPARE:
			# Lógica para Pride prepare
			pass
		PrideSubState.ATTACK:
			# Lógica para Pride attack
			pass
		PrideSubState.SPECIAL:
			# Lógica para Pride special
			pass
	
	# Movimento básico
	var direction = global_position.direction_to(player.global_position)
	velocity = direction * speed * delta
	move_and_slide()

func handle_greed(delta: float):
	# Implemente lógica específica para Greed
	pass

func handle_wrath(delta: float):
	# Implemente lógica específica para Wrath
	pass

func handle_envy(delta: float):
	# Implemente lógica específica para Envy
	pass

func handle_lust(delta: float):
	# Implemente lógica específica para Lust
	pass

func handle_gluttony(delta: float):
	# Implemente lógica específica para Gluttony
	pass

func handle_sloth(delta: float):
	# Implemente lógica específica para Sloth
	pass

func take_damage(amount: float) -> void:
	current_health -= int(round(amount))
	if current_health <= 0:
		die()
		return
	
	# Tween para dano
	var tween = create_tween()
	tween.tween_property(aparencia, "modulate", Color.RED, 0.1)
	tween.tween_property(aparencia, "modulate", Color.WHITE, 0.1)

func die() -> void:
	if player and player.has_method("gain_xp"):
		player.gain_xp(xp_drop)
	if player and player.has_method("on_enemy_killed"):
		player.on_enemy_killed(self)
	
	Global.pecado += 1
	
	queue_free()
