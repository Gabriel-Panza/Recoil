extends HSlider

func _on_value_changed(value: float) -> void:
	for musica in get_tree().get_nodes_in_group("Music"):
		musica.set_volume_db(value)
		Global.somVolume = value

func _on_h_slider_2_value_changed(value: float) -> void:
	for som in get_tree().get_nodes_in_group("SFX"):
		som.set_volume_db(value)
		Global.somSFX = value
