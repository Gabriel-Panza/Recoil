extends Panel

var player_path: NodePath = "/root/GameScene/Player"
var player
var game_scene_path: NodePath = "/root/GameScene"
var game_scene
var speedPlayer
var speedEnemy
var speedProjectile
var passive_options = [
	{ "id": "option_1", "text": "Recoil Force (+5%)", "rarity": "passive_common" },
	{ "id": "option_2", "text": "Health (+5%)", "rarity": "passive_common" },
	{ "id": "option_3", "text": "Attack (+10%)", "rarity": "passive_common" },
	{ "id": "option_4", "text": "Atk-Speed (+3%)", "rarity": "passive_common" }
]
var active_options = [
	{ "id": "Shield_Protection", "text": " Gain a one-hit shield", "rarity": "active" },
	{ "id": "recoil_explosion", "text": " Your next recoil creates a small shockwave", "rarity": "active" }
]
var boss_options = [
	{ "id": "wrath_overheat", "text": "Wrath: Every 3th shot deals double damage", "rarity": "passive_sin" },
	{ "id": "active_wrath_burst", "text": "Wrath: Fire a radial burst of bullets", "rarity": "active_sin" },
	{ "id": "pride_fall", "text": "Pride: Huge damage at full HP, but lose bonus when hit", "rarity": "passive_sin" },
	{ "id": "active_pride_perfection", "text": "Pride: Become invulnerable briefly", "rarity": "active_sin" },
	{ "id": "gluttony_heal_xp", "text": "Gluttony: Heal a small amount when collecting XP", "rarity": "passive_sin" },
	{ "id": "active_gluttony_devour", "text": "Gluttony: Consume nearby XP to heal yourself", "rarity": "active_sin" },
	{ "id": "greed_cursed_xp", "text": "Greed: XP +30%, but enemies move +10% faster", "rarity": "passive_sin" },
	{ "id": "active_greed_treasure_rain", "text": "Greed: Rain golden projectiles from above", "rarity": "active_sin" },
	{ "id": "sloth_slow_aura", "text": "Sloth: Enemies near you move slower", "rarity": "passive_sin" },
	{ "id": "active_sloth_field", "text": "Sloth: Create a field that slows all nearby enemies", "rarity": "active_sin" },
	{ "id": "envy_mirror_shot", "text": "Envy: Chance to fire a second mirrored bullet", "rarity": "passive_sin" },
	{ "id": "active_envy_mirror_clone", "text": "Envy: Summon a mirror clone that shoots with you", "rarity": "active_sin" },	{ "id": "active_pride_perfection", "text": "Pride: Become invulnerable and stronger for a short time", "rarity": "active_sin" },
	{ "id": "lust_dangerous_attraction", "text": "Lust: Enemies drop more XP, but chase you faster", "rarity": "passive_sin" },
	{ "id": "active_lust_charm_wave", "text": "Lust: Charm nearby enemies for a few seconds", "rarity": "active_sin" }
]
signal option_selected(option)

func _ready() -> void:
	randomize()
	game_scene = get_node_or_null(game_scene_path)
	player = get_node_or_null(player_path)
	visible = false

func show_popup():
	get_tree().paused = true
	
	await get_tree().create_timer(0.25).timeout
	
	# Começa com as opções básicas e randomiza 3 opções do vetor de opções
	var current_pool = passive_options.duplicate()
	current_pool.shuffle()
	visible = true 
	var randomized_options = current_pool.slice(0, 3)
	
	# Verifica a possibilidade de vir uma habilidade ativa
	var active_chance = 0.05
	if randf() < active_chance:
		active_options.shuffle()
		randomized_options[0] = active_options[0]
		randomized_options.shuffle()
	
	# Atualiza os botões com as opções randomizadas
	for i in range(3):
		var button = get_node_or_null("VBoxContainer").get_child(i)
		if i < randomized_options.size():
			button.visible = true
			button.get_child(0).text = randomized_options[i]["text"]
			if randomized_options[i]["rarity"] == "passive_common":
				button.self_modulate = Color(0, 1, 0.2, 1) # Verde
			else:
				button.self_modulate = Color(1, 0, 0.2, 1) # Vermelho
			button.disconnect("pressed", Callable(self, "_on_option_pressed"))
			button.connect("pressed", Callable(self, "_on_option_pressed").bind(randomized_options[i]["id"]))
		else:
			button.visible = false

func _on_option_pressed(option_id: String) -> void:
	emit_signal("option_selected", option_id)
	hide()
	
	get_tree().paused = false
	player.upando = false
	if player.current_xp >= player.xp_to_next_level:
		player.level_up()
