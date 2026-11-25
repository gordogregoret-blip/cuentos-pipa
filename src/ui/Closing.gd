class_name Closing
extends Control
## Cierre común (P7): semilla de luz, mensaje en una frase, "¿Cómo te
## sentiste?" (opcional) y los botones Leer otra vez / Probar otro camino /
## Volver a la plaza. En cuentos de prueba: "Continuará" y Volver a la plaza.

signal read_again
signal other_path
signal to_plaza

const UI_VO := "res://audio/ui/%s.ogg"
const ORDER := ["amarillo", "azul", "rojo", "violeta", "verde", "naranja"]

var message_label: Label
var answer_label: Label
var emotion_buttons: Array[Button] = []
var action_buttons: Array[Button] = []
var chosen_emotion: String = ""
var is_preview: bool = false

var _box: VBoxContainer
var _seed: TextureRect


func _init() -> void:
	name = "Closing"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false
	var shade := ColorRect.new()
	shade.color = Color(UiTheme.WALL, 0.75)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.custom_minimum_size = Vector2(1400, 0)
	add_child(panel)
	_box = VBoxContainer.new()
	_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_box.add_theme_constant_override("separation", 22)
	panel.add_child(_box)


func show_closing(data: StoryData) -> void:
	is_preview = false
	_reset()
	_seed = _image("res://art/ui/semilla.svg", 150)
	message_label = _label(data.message, 56)
	_label(tr("HOW_DID_YOU_FEEL"), 40)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 26)
	_box.add_child(row)
	for c in ORDER:
		var b := Button.new()
		b.name = c
		b.custom_minimum_size = Vector2(190, 130)
		b.text = tr("EMO_" + c)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 36)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Pendant.COLORS[c]
		sb.set_corner_radius_all(65)
		sb.set_border_width_all(6)
		sb.border_color = UiTheme.INK
		for st in ["normal", "hover", "pressed", "focus"]:
			b.add_theme_stylebox_override(st, sb)
		b.pressed.connect(choose_emotion.bind(c))
		row.add_child(b)
		emotion_buttons.append(b)
	answer_label = _label("", 40)
	var actions := _actions()
	_action(actions, "BTN_READ_AGAIN", "repetir", read_again)
	_action(actions, "BTN_OTHER_PATH", "siguiente", other_path)
	_action(actions, "BTN_PLAZA", "casa", to_plaza)
	visible = true
	_plant_seed()
	Audio.play_voice(data.message_vo_path())


func show_preview() -> void:
	is_preview = true
	_reset()
	_image("res://art/ui/lumi.svg", 160)
	message_label = _label(tr("TO_BE_CONTINUED"), 64)
	var actions := _actions()
	_action(actions, "BTN_PLAZA", "casa", to_plaza)
	visible = true
	Audio.play_voice(UI_VO % "to_be_continued")


func choose_emotion(color: String) -> void:
	chosen_emotion = color
	for b in emotion_buttons:
		b.scale = Vector2(1.12, 1.12) if b.name == color else Vector2.ONE
		b.pivot_offset = b.size / 2.0
	answer_label.text = tr("EMO_" + color)
	Audio.play_voice(UI_VO % ("emo_" + color))


func close() -> void:
	visible = false


func _plant_seed() -> void:
	if _seed == null or not is_inside_tree():
		return
	_seed.pivot_offset = Vector2(75, 75)
	_seed.scale = Vector2(0.6, 0.6)
	_seed.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(_seed, "modulate:a", 1.0, 0.6)
	t.parallel().tween_property(_seed, "scale", Vector2.ONE, 0.8).set_trans(Tween.TRANS_SINE)


func _reset() -> void:
	for c in _box.get_children():
		c.queue_free()
	emotion_buttons.clear()
	action_buttons.clear()
	chosen_emotion = ""
	_seed = null
	answer_label = Label.new()


func _label(text: String, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	_box.add_child(l)
	return l


func _image(path: String, side: int) -> TextureRect:
	var r := TextureRect.new()
	r.texture = load(path)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.custom_minimum_size = Vector2(side, side)
	r.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_box.add_child(r)
	return r


func _actions() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 36)
	_box.add_child(row)
	return row


func _action(row: HBoxContainer, key: String, icon: String, sig: Signal) -> void:
	var b := Button.new()
	b.name = key
	b.text = tr(key)
	b.icon = load("res://art/ui/%s.svg" % icon)
	b.expand_icon = false
	b.add_theme_constant_override("icon_max_width", 72)
	b.custom_minimum_size = Vector2(380, 120)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 38)
	b.pressed.connect(func() -> void: sig.emit())
	row.add_child(b)
	action_buttons.append(b)
