class_name AdultPanel
extends Overlay
## Panel del adulto (solo detrás de la puerta para padres). Todo se guarda
## al instante en el dispositivo.

signal settings_changed

const SPEEDS := [0.8, 1.0, 1.2]

var index: StoryIndex
var link_buttons: Array[Button] = []
var erase_confirm: Control

var _col: VBoxContainer
var _endings: Label
var _age_label: Label


func _init() -> void:
	super()
	name = "AdultPanel"
	add_shade(0.96)


func _ready() -> void:
	rebuild()


func rebuild() -> void:
	for c in get_children():
		if c is ScrollContainer or c == erase_confirm:
			c.queue_free()
	link_buttons.clear()
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 120
	scroll.offset_right = -120
	scroll.offset_top = 40
	scroll.offset_bottom = -40
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_col = VBoxContainer.new()
	_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_col.add_theme_constant_override("separation", 26)
	scroll.add_child(_col)

	var head := HBoxContainer.new()
	var title := Overlay.label(tr("ADULT_TITLE"), UiTheme.TITLE_SIZE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	var close := Overlay.text_button("ADULT_CLOSE", "no", 280)
	close.pressed.connect(func() -> void: close_requested.emit())
	head.add_child(close)
	_col.add_child(head)

	_section("ADULT_LEVEL")
	_choices(["simple", "cuento", "aventura"], String(Store.level()), func(v: String) -> String: return tr("LEVEL_" + v), set_level)
	_section("ADULT_AGE")
	var age_row := Overlay.row()
	var minus := Overlay.text_button("−", "", 140)
	minus.text = "−"
	minus.pressed.connect(func() -> void: set_age(int(Store.data["age"]) - 1))
	_age_label = Overlay.label(str(Store.data["age"]), 56)
	_age_label.custom_minimum_size = Vector2(160, 0)
	var plus := Overlay.text_button("+", "", 140)
	plus.text = "+"
	plus.pressed.connect(func() -> void: set_age(int(Store.data["age"]) + 1))
	age_row.add_child(minus)
	age_row.add_child(_age_label)
	age_row.add_child(plus)
	_col.add_child(age_row)

	for key in ["vol_voz", "vol_efectos", "vol_musica"]:
		_section("ADULT_" + key.to_upper())
		var s := HSlider.new()
		s.min_value = 0.0
		s.max_value = 1.0
		s.step = 0.05
		s.value = Store.setting(key)
		s.custom_minimum_size = Vector2(900, 64)
		s.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		s.value_changed.connect(func(v: float) -> void: set_volume(key, v))
		_col.add_child(s)

	_section("ADULT_SPEED")
	_choices(SPEEDS.map(func(x: float) -> String: return str(x)), str(Store.setting("speed")), func(v: String) -> String: return v + "×", func(v: String) -> void: set_speed(float(v)))

	for key in ["calm", "subtitles", "lock_taps", "easy_font"]:
		var cb := CheckButton.new()
		cb.text = tr({"calm": "ADULT_CALM", "subtitles": "ADULT_SUBTITLES", "lock_taps": "ADULT_LOCK", "easy_font": "ADULT_EASY_FONT"}[key])
		cb.button_pressed = Store.setting(key)
		cb.custom_minimum_size = Vector2(0, 80)
		cb.add_theme_font_size_override("font_size", 40)
		cb.focus_mode = Control.FOCUS_NONE
		cb.toggled.connect(func(on: bool) -> void: set_toggle(key, on))
		_col.add_child(cb)

	_section("ADULT_TURN")
	_choices(["button", "swipe"], Store.setting("turn_mode"), func(v: String) -> String: return tr("ADULT_TURN_" + v), set_turn_mode)
	_section("ADULT_LANGUAGE")
	_choices(["es", "en"], Store.setting("locale"), func(v: String) -> String: return {"es": "Español", "en": "English"}[v], func(v: String) -> void:
		Store.set_setting("locale", v)
		rebuild.call_deferred())

	_section("ADULT_ENDINGS")
	_endings = Overlay.label(endings_text(), 38)
	_endings.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_col.add_child(_endings)

	var links := Overlay.row()
	for pair in [["ADULT_PRIVACY", Links.PRIVACY], ["ADULT_MORE", Links.MORE_STORIES], ["ADULT_CONTACT", Links.CONTACT]]:
		var b := Overlay.text_button(pair[0], "", 360)
		var url: String = pair[1]
		b.pressed.connect(func() -> void: OS.shell_open(url))
		links.add_child(b)
		link_buttons.append(b)
	_col.add_child(links)

	var erase := Overlay.text_button("ADULT_ERASE", "", 420)
	erase.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	erase.pressed.connect(request_erase)
	_col.add_child(erase)
	_col.add_child(Overlay.label("v" + str(ProjectSettings.get_setting("application/config/version", "")), 30))

	erase_confirm = Control.new()
	erase_confirm.set_anchors_preset(Control.PRESET_FULL_RECT)
	erase_confirm.visible = false
	var shade := ColorRect.new()
	shade.color = Color(UiTheme.WALL, 0.9)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	erase_confirm.add_child(shade)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.add_theme_constant_override("separation", 40)
	box.add_child(Overlay.label(tr("ADULT_ERASE_CONFIRM"), 44))
	var r := Overlay.row()
	var no := UiTheme.icon_button("no", "BTN_NO", 150)
	no.pressed.connect(func() -> void: erase_confirm.visible = false)
	var yes := UiTheme.icon_button("si", "BTN_YES", 150)
	yes.pressed.connect(confirm_erase)
	r.add_child(no)
	r.add_child(yes)
	box.add_child(r)
	erase_confirm.add_child(box)
	add_child(erase_confirm)


func set_level(v: String) -> void:
	Store.set_setting("level", v)
	settings_changed.emit()


func set_age(age: int) -> void:
	Store.set_age(age)
	if _age_label:
		_age_label.text = str(Store.data["age"])
	settings_changed.emit()


func set_volume(key: String, v: float) -> void:
	Store.set_setting(key, v)
	Audio.set_bus_volume({"vol_voz": &"Voz", "vol_efectos": &"Efectos", "vol_musica": &"Musica"}[key], v)


func set_speed(v: float) -> void:
	Store.set_setting("speed", v)
	Audio.set_speed(v)


func set_toggle(key: String, on: bool) -> void:
	Store.set_setting(key, on)
	settings_changed.emit()


func set_turn_mode(v: String) -> void:
	Store.set_setting("turn_mode", v)


func endings_text() -> String:
	var lines: PackedStringArray = []
	if index == null:
		return ""
	for e in index.playable():
		var data := StoryData.load_from(index.dir_for(e["id"]))
		if data == null:
			continue
		lines.append("%s: %d / %d" % [e["title"], Store.endings_for(e["id"]).size(), data.ending_ids().size()])
	return "\n".join(lines)


func request_erase() -> void:
	erase_confirm.visible = true


func confirm_erase() -> void:
	Store.clear_progress()
	erase_confirm.visible = false
	if _endings:
		_endings.text = endings_text()
	settings_changed.emit()


## Atrás con la confirmación de borrado abierta: cierra solo esa pregunta.
func handle_back() -> bool:
	if erase_confirm and erase_confirm.visible:
		erase_confirm.visible = false
		return true
	return false


func _section(key: String) -> void:
	var l := Overlay.label(tr(key), 44)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_col.add_child(l)


func _choices(values: Array, current: String, label_of: Callable, on_pick: Callable) -> void:
	var r := Overlay.row()
	var group := ButtonGroup.new()
	for v in values:
		var b := Button.new()
		b.text = label_of.call(v)
		b.toggle_mode = true
		b.button_group = group
		b.button_pressed = String(v) == current
		b.custom_minimum_size = Vector2(280, 100)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 40)
		var val: String = v
		b.pressed.connect(func() -> void: on_pick.call(val))
		r.add_child(b)
	_col.add_child(r)
