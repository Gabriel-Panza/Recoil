extends Control

func _on_start_game_pressed() -> void:
	$SFX.play()
	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://Cenas/gameScene.tscn")
	
func _on_button_2_pressed() -> void:
	$SFX.play()
	await get_tree().create_timer(0.1).timeout
	get_tree().quit()

func _on_options_button_pressed() -> void:
	$SFX.play()
	$OptionsMenu.visible = true
