extends Control

@onready var ranking_panel: Control = $RankingPanel
@onready var ranking_list: VBoxContainer = $RankingPanel/ScrollContainer/RankingList

func _ready() -> void:
	ranking_panel.visible = false

func _on_start_game_pressed() -> void:
	_play_sfx()
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://Cenas/General/gameScene.tscn")
	
func _on_button_2_pressed() -> void:
	_play_sfx()
	await get_tree().create_timer(0.1).timeout
	get_tree().quit()

func _on_options_button_pressed() -> void:
	_play_sfx()
	$OptionsMenu.visible = true
	$Menu.visible = false

func _on_ranking_button_pressed() -> void:
	_play_sfx()
	_refresh_ranking()
	ranking_panel.visible = true
	$Menu.visible = false

func _on_ranking_back_pressed() -> void:
	_play_sfx()
	ranking_panel.visible = false
	$Menu.visible = true

func _refresh_ranking() -> void:
	for child in ranking_list.get_children():
		child.queue_free()

	var runs = Global.get_ranked_runs()
	if runs.is_empty():
		_add_ranking_label("Nenhuma run registrada ainda.")
		return

	for i in range(runs.size()):
		var run = runs[i]
		var ranking_text = "%02d. %s - %s" % [
			i + 1,
			str(run.get("pecados_texto", "0 pecados derrotados")),
			str(run.get("tempo_formatado", "00:00"))
		]
		_add_ranking_label(ranking_text, str(run.get("data", "")))

func _add_ranking_label(text: String, tooltip: String = "") -> void:
	var label = Label.new()
	label.text = text
	label.tooltip_text = tooltip
	label.add_theme_color_override("font_color", Color(0.88, 0.0, 0.0))
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_font_size_override("font_size", 24)
	ranking_list.add_child(label)

func _play_sfx() -> void:
	var sfx = get_node_or_null("SFX_Button")
	if sfx:
		sfx.play()
