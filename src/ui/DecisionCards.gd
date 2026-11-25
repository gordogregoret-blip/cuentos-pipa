class_name DecisionCards
extends Control
## Dos tarjetas grandes (imagen + texto + voz). Sin límite de tiempo.

signal chosen(index: int)

const CARD := Vector2(600, 540)

var cards: Array[Button] = []
var _queue: Array[String] = []


func _init() -> void:
	name = "DecisionCards"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func show_options(data: StoryData, page_id: String) -> void:
	for c in get_children():
		c.queue_free()
	cards.clear()
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_CENTER)
	row.grow_horizontal = Control.GROW_DIRECTION_BOTH
	row.grow_vertical = Control.GROW_DIRECTION_BOTH
	row.add_theme_constant_override("separation", 80)
	row.offset_top = -CARD.y / 2.0 - 60.0
	add_child(row)
	var options: Array = data.page(page_id)["decision"]["options"]
	for i in options.size():
		var b := _card(data, options[i])
		b.pressed.connect(_on_pressed.bind(i))
		row.add_child(b)
		cards.append(b)
	visible = true
	_queue = [data.option_vo_path(page_id, 0), data.option_vo_path(page_id, 1)]
	_say_next()


func close() -> void:
	visible = false
	_queue.clear()
	if Audio.voice_finished.is_connected(_say_next):
		Audio.voice_finished.disconnect(_say_next)


func _say_next() -> void:
	if Audio.voice_finished.is_connected(_say_next):
		Audio.voice_finished.disconnect(_say_next)
	if _queue.is_empty() or not visible:
		return
	var idx := 2 - _queue.size()
	for i in cards.size():
		cards[i].modulate = Color.WHITE if i == idx else Color(1, 1, 1, 0.92)
	Audio.voice_finished.connect(_say_next, CONNECT_ONE_SHOT)
	Audio.play_voice(_queue.pop_front())


func _on_pressed(i: int) -> void:
	close()
	chosen.emit(i)


func _card(data: StoryData, opt: Dictionary) -> Button:
	var b := Button.new()
	b.custom_minimum_size = CARD
	b.focus_mode = Control.FOCUS_NONE
	b.name = "Opcion"
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.offset_left = 24
	box.offset_right = -24
	box.offset_top = 24
	box.offset_bottom = -24
	box.add_theme_constant_override("separation", 16)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var img := TextureRect.new()
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img.size_flags_vertical = Control.SIZE_EXPAND_FILL
	img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var path := data.asset(opt["image"])
	img.texture = load(path) if ResourceLoader.exists(path) else null
	var label := Label.new()
	label.text = opt["text"]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 44)
	box.add_child(img)
	box.add_child(label)
	b.add_child(box)
	return b
