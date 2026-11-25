class_name Controls
extends Control
## Controles fijos del cuento, siempre en el mismo lugar:
## arriba: plaza | indicador "3 de 7" | repetir, calma
## abajo: atrás | (texto) | siguiente

signal back_pressed
signal next_pressed
signal repeat_pressed
signal calm_pressed
signal plaza_pressed

const PAD := 28.0

var back_button: Button
var next_button: Button
var repeat_button: Button
var calm_button: Button
var plaza_button: Button
var indicator: Label
var dots: HBoxContainer

var _step := 1
var _total := 7


func _init() -> void:
	name = "Controls"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	plaza_button = _corner(UiTheme.icon_button("casa", "BTN_PLAZA"), Control.PRESET_TOP_LEFT)
	repeat_button = _corner(UiTheme.icon_button("repetir", "BTN_REPEAT"), Control.PRESET_TOP_RIGHT)
	calm_button = _corner(UiTheme.icon_button("calma", "BTN_CALM"), Control.PRESET_TOP_RIGHT)
	back_button = _corner(UiTheme.icon_button("atras", "BTN_BACK", 128), Control.PRESET_BOTTOM_LEFT)
	next_button = _corner(UiTheme.icon_button("siguiente", "BTN_NEXT", 128), Control.PRESET_BOTTOM_RIGHT)
	plaza_button.pressed.connect(func() -> void: plaza_pressed.emit())
	repeat_button.pressed.connect(func() -> void: repeat_pressed.emit())
	calm_button.pressed.connect(func() -> void: calm_pressed.emit())
	back_button.pressed.connect(func() -> void: back_pressed.emit())
	next_button.pressed.connect(func() -> void: next_pressed.emit())

	var top := VBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_CENTER_TOP)
	top.grow_horizontal = Control.GROW_DIRECTION_BOTH
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dots = HBoxContainer.new()
	dots.alignment = BoxContainer.ALIGNMENT_CENTER
	dots.add_theme_constant_override("separation", 14)
	indicator = Label.new()
	indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	indicator.add_theme_font_size_override("font_size", 36)
	top.add_child(dots)
	top.add_child(indicator)
	add_child(top)
	apply_safe_area({"left": 0.0, "top": 0.0, "right": 0.0, "bottom": 0.0})


func set_step(step: int, total: int) -> void:
	_step = step
	_total = total
	indicator.text = indicator_text()
	for c in dots.get_children():
		c.queue_free()
	for i in total:
		var dot := Panel.new()
		dot.custom_minimum_size = Vector2(22, 22)
		var box := StyleBoxFlat.new()
		box.set_corner_radius_all(11)
		box.bg_color = UiTheme.SUN if i < step else UiTheme.CREAM
		box.set_border_width_all(4)
		box.border_color = UiTheme.INK
		dot.add_theme_stylebox_override("panel", box)
		dots.add_child(dot)


func indicator_text() -> String:
	return tr("PAGE_OF") % [_step, _total]


func all_buttons() -> Array[Button]:
	return [plaza_button, repeat_button, calm_button, back_button, next_button]


## m: márgenes de zona segura en coordenadas del lienzo.
func apply_safe_area(m: Dictionary) -> void:
	var l: float = m["left"] + PAD
	var r: float = m["right"] + PAD
	var t: float = m["top"] + PAD
	var b: float = m["bottom"] + PAD
	_place(plaza_button, Vector2(l, t), Vector2.ZERO)
	_place(repeat_button, Vector2(-r - repeat_button.custom_minimum_size.x, t), Vector2(1, 0))
	_place(calm_button, Vector2(-r - 2.0 * calm_button.custom_minimum_size.x - 24.0, t), Vector2(1, 0))
	_place(back_button, Vector2(l, -b - back_button.custom_minimum_size.y), Vector2(0, 1))
	_place(next_button, Vector2(-r - next_button.custom_minimum_size.x, -b - next_button.custom_minimum_size.y), Vector2(1, 1))
	var top := indicator.get_parent() as Control
	top.offset_top = t
	top.offset_bottom = t + 90.0


func _corner(b: Button, preset: int) -> Button:
	b.set_anchors_preset(preset)
	add_child(b)
	return b


func _place(b: Button, offset: Vector2, anchor: Vector2) -> void:
	b.anchor_left = anchor.x
	b.anchor_right = anchor.x
	b.anchor_top = anchor.y
	b.anchor_bottom = anchor.y
	b.offset_left = offset.x
	b.offset_top = offset.y
	b.offset_right = offset.x + b.custom_minimum_size.x
	b.offset_bottom = offset.y + b.custom_minimum_size.y
