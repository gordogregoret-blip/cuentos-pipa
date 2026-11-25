class_name Door
extends Control
## Una puerta del Árbol: abre un cuento, o queda cerrada con "Próximamente".
## Debajo, estrellas con los finales descubiertos.

signal opened(id: String)

const SIZE := Vector2(200, 260)

var id: String
var locked: bool
var stars_found: int = 0
var stars_total: int = 0
var sign_label: Label

var _stars: HBoxContainer
var _door: TextureRect


func setup(entry: Dictionary) -> void:
	id = entry["id"]
	name = "Door_" + id
	locked = entry.get("locked", false)
	custom_minimum_size = SIZE
	size = SIZE
	pivot_offset = Vector2(SIZE.x / 2.0, SIZE.y)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_door = _layer("res://art/ui/puerta.svg")
	_door.modulate = Color(entry.get("door_color", "#7FC28E"))
	if locked:
		_door.modulate = _door.modulate.lerp(Color("#C9C2BA"), 0.55)
		_layer("res://art/ui/puerta_cerrada.svg")
	_layer("res://art/ui/puerta_marco.svg")
	if locked:
		var sign := PanelContainer.new()
		sign.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sign_label = Label.new()
		sign_label.text = tr("COMING_SOON")
		sign_label.add_theme_font_size_override("font_size", 36)
		sign_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sign.add_child(sign_label)
		add_child(sign)
		sign.position = Vector2(-25, 80)
		sign.custom_minimum_size = Vector2(SIZE.x + 50, 0)
	_stars = HBoxContainer.new()
	_stars.alignment = BoxContainer.ALIGNMENT_CENTER
	_stars.position = Vector2(-20, SIZE.y + 6)
	_stars.custom_minimum_size = Vector2(SIZE.x + 40, 48)
	_stars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stars)


func set_stars(found: int, total: int) -> void:
	stars_found = found
	stars_total = total
	for c in _stars.get_children():
		c.queue_free()
	for i in total:
		var s := TextureRect.new()
		s.texture = load("res://art/ui/estrella.svg" if i < found else "res://art/ui/estrella_vacia.svg")
		s.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		s.custom_minimum_size = Vector2(44, 44)
		_stars.add_child(s)


func _gui_input(event: InputEvent) -> void:
	var pressed: bool = (event is InputEventScreenTouch and event.pressed) \
		or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	if pressed:
		press()
		accept_event()


func press() -> void:
	var t := create_tween() if is_inside_tree() else null
	if locked:
		Audio.play_voice("res://audio/ui/coming_soon.ogg")
		if t:
			for a in [0.05, -0.05, 0.0]:
				t.tween_property(self, "rotation", a, 0.12).set_trans(Tween.TRANS_SINE)
		return
	if t:
		t.tween_property(self, "scale", Vector2(1.06, 1.06), 0.12)
		t.tween_property(self, "scale", Vector2.ONE, 0.16)
	opened.emit(id)


func _layer(path: String) -> TextureRect:
	var r := TextureRect.new()
	r.texture = load(path)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)
	return r
