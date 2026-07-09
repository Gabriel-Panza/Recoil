extends HSlider

func _ready() -> void:
	Global.configure_music_slider(self)
	var sfx_slider = get_parent().get_node_or_null("HSlider2") as HSlider
	Global.configure_sfx_slider(sfx_slider)
	Global.apply_audio_volumes()

func _on_value_changed(value: float) -> void:
	Global.set_music_volume_from_slider(value)

func _on_h_slider_2_value_changed(value: float) -> void:
	Global.set_sfx_volume_from_slider(value)
