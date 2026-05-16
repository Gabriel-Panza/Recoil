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
var cursed_passive_options = [
	{ "id": "glass_canon", "text": "Attack (+25%), Health (-20%)", "rarity": "passive_cursed" },
	{ "id": "tanky", "text": "Health (+20%), Attack (-25%)", "rarity": "passive_cursed" },
	{ "id": "deadly_slow", "text": "Recoil Force (-50%), Attack (+50%)", "rarity": "passive_cursed" }
]
var active_options = [
	{ "id": "Shield_Protection", "text": "Gain a one-hit shield", "rarity": "active" },
	{ "id": "Recoil_Explosion", "text": "Your next recoil creates a small shockwave", "rarity": "active" },
	{ "id": "Double_Dash", "text": "You have two charges of dash", "rarity": "active" }
]
var boss_options = [
	{ "id": "sloth_slow_aura", "text": "Sloth: Enemies near you move slightly slower", "rarity": "passive_sin" },
	{ "id": "sloth_field", "text": "Sloth: Create a field that slows all enemies inside greatly, but you become slightly slow too", "rarity": "active_sin" },
	
	{ "id": "gluttony_heal_kill", "text": "Gluttony: Heal a small amount when killing enemies", "rarity": "passive_sin" },
	{ "id": "gluttony_devour", "text": "Gluttony: Consume two nearby enemies to heal yourself for a great amount, but become very slow for 5s", "rarity": "active_sin" },
	
	{ "id": "envy_mirror_shot", "text": "Envy: Chance to fire a second mirrored bullet", "rarity": "passive_sin" },
	{ "id": "envy_mirror_clone", "text": "Envy: Summon a mirror clone that shoots with you for some time, but the clone bullet can hit anything (including you)", "rarity": "active_sin" },	{ "id": "active_pride_perfection", "text": "Pride: Become invulnerable and stronger for a short time", "rarity": "active_sin" },

	{ "id": "wrath_overheat", "text": "Wrath: Every 3th shot deals double damage", "rarity": "passive_sin" },
	{ "id": "wrath_burst", "text": "Wrath: Fire a radial burst of bullets, but take some damage", "rarity": "active_sin" },
	
	{ "id": "lust_for_vengeance", "text": "Lust: Huge damage at full HP, but lose bonus when hit", "rarity": "passive_sin" },
	{ "id": "lust_for_perfection", "text": "Lust: Become invulnerable briefly, but take double damage for 5s after leaving invulnerability", "rarity": "active_sin" },
	
	{ "id": "greed_cursed_level", "text": "Greed: Gain 1 bonus level per wave. Enemies move +25% faster", "rarity": "passive_sin" },
	{ "id": "greed_treasure_rain", "text": "Greed: Rain golden projectiles from above, dealing damage to everything (including you)", "rarity": "active_sin" }
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
				button.self_modulate = Color(0, 1, 0.1, 1) # Verde
			elif randomized_options[i]["rarity"] == "active":
				button.self_modulate = Color(0.1, 0.0, 1, 1.0) # Roxo
			elif randomized_options[i]["rarity"] == "passive_cursed":
				button.self_modulate = Color(0.6, 0.0, 0.6, 1.0) # Roxo
			else:
				button.self_modulate = Color(1, 0, 0.1, 1) # Vermelho
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
