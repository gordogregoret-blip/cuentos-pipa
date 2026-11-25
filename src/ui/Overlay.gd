class_name Overlay
extends Control
## Capa encima de la pantalla (portada, calma, puerta para padres, panel...).
## Main las apila; el botón Atrás de Android cierra la de arriba.

signal close_requested


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


## Fondo suave que tapa la pantalla de abajo.
func add_shade(alpha: float = 0.82) -> void:
	var shade := ColorRect.new()
	shade.color = Color(UiTheme.WALL, alpha)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)


## Panel centrado con una columna.
func add_column(width: float = 1200.0) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.custom_minimum_size = Vector2(width, 0)
	add_child(panel)
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 24)
	panel.add_child(col)
	return col


static func label(text: String, size: int = UiTheme.UI_SIZE) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	return l


static func text_button(key: String, icon: String = "", min_w: float = 360.0) -> Button:
	var b := Button.new()
	b.name = key
	b.text = TranslationServer.translate(key)
	if icon != "":
		b.icon = load("res://art/ui/%s.svg" % icon)
		b.add_theme_constant_override("icon_max_width", 72)
	b.custom_minimum_size = Vector2(min_w, 116)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 40)
	return b


static func row() -> HBoxContainer:
	var r := HBoxContainer.new()
	r.alignment = BoxContainer.ALIGNMENT_CENTER
	r.add_theme_constant_override("separation", 32)
	return r
