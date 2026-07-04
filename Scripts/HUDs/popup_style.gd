class_name PopupStyle
extends RefCounted

const OVERLAY_COLOR: Color = Color(0.02, 0.01, 0.015, 0.88)
const PANEL_BG: Color = Color(0.10, 0.045, 0.055, 0.96)
const PANEL_BORDER: Color = Color(0.95, 0.25, 0.12, 0.92)
const BUTTON_BG: Color = Color(0.16, 0.07, 0.075, 0.98)
const BUTTON_BORDER: Color = Color(0.52, 0.18, 0.12, 0.95)
const BUTTON_HOVER_BG: Color = Color(0.26, 0.10, 0.08, 0.98)
const BUTTON_HOVER_BORDER: Color = Color(1.0, 0.54, 0.20, 1.0)
const BUTTON_PRESSED_BG: Color = Color(0.34, 0.13, 0.08, 0.98)
const BUTTON_PRESSED_BORDER: Color = Color(1.0, 0.76, 0.28, 1.0)
const BUTTON_DISABLED_BG: Color = Color(0.08, 0.04, 0.045, 0.88)
const BUTTON_DISABLED_BORDER: Color = Color(0.28, 0.10, 0.08, 0.85)
const TITLE_COLOR: Color = Color(1.0, 0.72, 0.42, 1.0)
const TEXT_COLOR: Color = Color(0.95, 0.86, 0.76, 1.0)
const BUTTON_TEXT_COLOR: Color = Color(1.0, 0.95, 0.82, 1.0)
const DISABLED_TEXT_COLOR: Color = Color(0.58, 0.45, 0.38, 1.0)

static func make_style(bg_color: Color, border_color: Color, border_width: int) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(6)
	style.content_margin_left = 14
	style.content_margin_top = 12
	style.content_margin_right = 14
	style.content_margin_bottom = 12
	return style

static func apply_panel(control: Control) -> void:
	if control == null:
		return
	control.add_theme_stylebox_override("panel", make_style(PANEL_BG, PANEL_BORDER, 3))

static func apply_button(button: Button) -> void:
	if button == null:
		return
	button.add_theme_color_override("font_color", BUTTON_TEXT_COLOR)
	button.add_theme_color_override("font_hover_color", BUTTON_TEXT_COLOR)
	button.add_theme_color_override("font_pressed_color", BUTTON_TEXT_COLOR)
	button.add_theme_color_override("font_hover_pressed_color", BUTTON_TEXT_COLOR)
	button.add_theme_color_override("font_disabled_color", DISABLED_TEXT_COLOR)
	button.add_theme_stylebox_override("normal", make_style(BUTTON_BG, BUTTON_BORDER, 2))
	button.add_theme_stylebox_override("hover", make_style(BUTTON_HOVER_BG, BUTTON_HOVER_BORDER, 3))
	button.add_theme_stylebox_override("pressed", make_style(BUTTON_PRESSED_BG, BUTTON_PRESSED_BORDER, 3))
	button.add_theme_stylebox_override("disabled", make_style(BUTTON_DISABLED_BG, BUTTON_DISABLED_BORDER, 2))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

static func apply_title(label: Label) -> void:
	if label == null:
		return
	label.add_theme_color_override("font_color", TITLE_COLOR)

static func apply_text(label: Label) -> void:
	if label == null:
		return
	label.add_theme_color_override("font_color", TEXT_COLOR)
