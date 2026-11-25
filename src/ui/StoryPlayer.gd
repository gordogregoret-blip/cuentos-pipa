class_name StoryPlayer
extends Control
## Reproduce cualquier story.json: páginas, transición de hoja (o fundido en
## modo calma), relato automático con karaoke, tocables y controles fijos.

signal page_shown(page_id: String)
signal transition_finished
signal narration_finished
signal exit_requested

@export var turn_time: float = 0.4
@export var narration_delay: float = 0.3

var data: StoryData
var state: StoryState
var narrator: Narrator
var controls: Controls
var page_view: PageView
var text_panel: PanelContainer
var text_label: RichTextLabel
var decision_cards: DecisionCards
var closing: Closing
var last_transition: StringName = &""
var pendant_color: String = "amarillo"
var hint := HintTimer.new(6.0)

var _layer: Control
var _transitioning: bool = false
var _swipe := SwipeDetector.new()
var _words: PackedStringArray = []
var _narration_done: bool = false
var _delay: SceneTreeTimer
var _held: bool = false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_layer = Control.new()
	_layer.name = "Pages"
	_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_layer.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_layer)

	text_panel = PanelContainer.new()
	text_panel.name = "TextPanel"
	text_panel.anchor_left = 0.5
	text_panel.anchor_right = 0.5
	text_panel.anchor_top = 1.0
	text_panel.anchor_bottom = 1.0
	text_panel.offset_left = -790
	text_panel.offset_right = 790
	text_panel.offset_top = -28
	text_panel.offset_bottom = -28
	text_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	text_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_label = RichTextLabel.new()
	text_label.bbcode_enabled = true
	text_label.fit_content = true
	text_label.scroll_active = false
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.add_theme_font_size_override("normal_font_size", UiTheme.READ_SIZE)
	text_label.add_theme_constant_override("line_separation", 10)
	text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_panel.add_child(text_label)
	add_child(text_panel)

	decision_cards = DecisionCards.new()
	decision_cards.chosen.connect(choose)
	add_child(decision_cards)
	closing = Closing.new()
	closing.read_again.connect(_read_again)
	closing.other_path.connect(_other_path)
	closing.to_plaza.connect(func() -> void: exit_requested.emit())
	add_child(closing)

	controls = Controls.new()
	add_child(controls)
	controls.next_pressed.connect(next)
	controls.back_pressed.connect(handle_back)
	controls.repeat_pressed.connect(repeat)
	controls.plaza_pressed.connect(func() -> void: exit_requested.emit())

	narrator = Narrator.new()
	narrator.name = "Narrator"
	add_child(narrator)
	narrator.word.connect(_highlight)
	narrator.word.connect(_on_word)
	narrator.finished.connect(_on_narration_finished)
	refresh_settings()
	get_viewport().size_changed.connect(_apply_safe_area)
	_apply_safe_area()


func open(story_dir: String, resume: Dictionary = {}) -> bool:
	data = StoryData.load_from(story_dir)
	if data == null:
		return false
	state = StoryState.new(data)
	pendant_color = "amarillo"
	if resume.is_empty() or not state.from_dict(resume):
		state.start()
	_show_page(&"none")
	return true


func is_transitioning() -> bool:
	return _transitioning


func next() -> void:
	if _transitioning or state == null:
		return
	if state.go_next():
		_show_page(&"forward")


func choose(index: int) -> void:
	if _transitioning or state == null:
		return
	if state.choose(index):
		_show_page(&"forward")


## Botón Atrás (de la app o de Android). Siempre consume el evento:
## en la primera página pide volver a la plaza.
func handle_back() -> bool:
	if _transitioning or state == null:
		return true
	if state.back():
		_show_page(&"back")
	else:
		exit_requested.emit()
	return true


func repeat() -> void:
	if _transitioning or state == null:
		return
	_start_narration()


## Rincón de calma: se detiene el relato y la pista de Lumi.
func hold() -> void:
	_held = true
	narrator.stop()
	if _delay:
		_delay.timeout.disconnect(_start_narration)
		_delay = null


## "Volver al cuento": la página se vuelve a leer desde el principio.
func resume_after_hold() -> void:
	_held = false
	hint.touch()
	if not _transitioning:
		_delay = get_tree().create_timer(narration_delay)
		_delay.timeout.connect(_start_narration)


func refresh_settings() -> void:
	Motion.reduced = Store.setting("calm")
	text_panel.visible = Store.setting("subtitles")
	theme = UiTheme.build(Store.setting("easy_font"))


func narration_done() -> bool:
	return _narration_done


func _show_page(direction: StringName) -> void:
	narrator.stop()
	_narration_done = false
	if _delay:
		_delay.timeout.disconnect(_start_narration)
		_delay = null
	var old := page_view
	page_view = PageView.new()
	page_view.build(data, state.current)
	page_view.tapped.connect(_on_tapped)
	page_view.set_pendant(pendant_color)
	hint.touch()
	decision_cards.close()
	closing.close()
	text_panel.visible = Store.setting("subtitles")
	_set_text(-1)
	_update_controls()
	if state.kind() == &"closing":
		Store.add_seed(data.id)
		Store.clear_resume(data.id)
	else:
		Store.set_resume(data.id, state.to_dict())
	var ending := state.ending()
	if not ending.is_empty():
		Store.record_ending(data.id, ending["id"])
	_set_taps_locked(Store.setting("lock_taps"))

	if old == null or direction == &"none":
		_layer.add_child(page_view)
		if old:
			old.queue_free()
		_end_transition()
		return
	_transitioning = true
	var calm: bool = Store.setting("calm")
	last_transition = &"fade" if calm else &"turn"
	var t := create_tween()
	if calm:
		_layer.add_child(page_view)
		_layer.move_child(old, -1)
		t.tween_property(old, "modulate:a", 0.0, turn_time).set_trans(Tween.TRANS_SINE)
	elif direction == &"forward":
		# La hoja vieja se da vuelta sobre su borde izquierdo y deja ver la nueva.
		_layer.add_child(page_view)
		_layer.move_child(old, -1)
		old.pivot_offset = Vector2.ZERO
		t.tween_property(old, "scale:x", 0.0, turn_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		t.parallel().tween_property(old, "modulate", Color(0.85, 0.85, 0.85), turn_time)
	else:
		# Atrás: la hoja anterior vuelve a cubrir la página.
		_layer.add_child(page_view)
		page_view.pivot_offset = Vector2.ZERO
		page_view.scale.x = 0.0
		t.tween_property(page_view, "scale:x", 1.0, turn_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_callback(old.queue_free)
	t.tween_callback(_end_transition)


func _end_transition() -> void:
	_transitioning = false
	transition_finished.emit()
	page_shown.emit(state.current)
	_delay = get_tree().create_timer(narration_delay)
	_delay.timeout.connect(_start_narration)


func _start_narration() -> void:
	_delay = null
	if _held:
		return
	var level := Store.level()
	_narration_done = false
	_set_text(-1)
	narrator.narrate(data.text(state.current, level), data.vo_path(state.current, level), data.timings_path(state.current, level))
	if page_view.pipa:
		page_view.pipa.talk_for(narrator.duration)


func _on_narration_finished() -> void:
	_narration_done = true
	_set_taps_locked(false)
	_apply_pendant(1.0)
	hint.touch()
	match state.kind():
		&"decision":
			decision_cards.show_options(data, state.current)
		&"closing":
			text_panel.visible = false
			closing.show_closing(data)
		&"end_preview":
			Store.clear_resume(data.id)
			text_panel.visible = false
			closing.show_preview()
	narration_finished.emit()


func _read_again() -> void:
	if _transitioning:
		return
	Store.clear_resume(data.id)
	state.start()
	pendant_color = "amarillo"
	_show_page(&"forward")


func _other_path() -> void:
	if _transitioning:
		return
	if state.rewind_to_last_decision():
		_show_page(&"back")


func _on_word(_i: int) -> void:
	if narrator.duration > 0.0:
		_apply_pendant(narrator.clock / narrator.duration)


func _apply_pendant(fraction: float) -> void:
	var c := Pendant.due(state.page().get("pendant", []), fraction)
	if c != "" and c != pendant_color:
		pendant_color = c
		page_view.set_pendant(c, true)


func _process(delta: float) -> void:
	tick_hint(delta)


## Pista de Lumi: 6 s sin tocar nada después del relato.
func tick_hint(dt: float) -> void:
	if not _narration_done or _transitioning or _held or Audio.paused or page_view == null:
		return
	if hint.tick(dt):
		var pick: Tappable = null
		for t in page_view.tappables:
			if t.times_tapped == 0 and not t.locked:
				pick = t
				break
		if pick == null and not page_view.tappables.is_empty():
			pick = page_view.tappables[0]
		if pick:
			pick.show_hint(true)


func _on_tapped(def: Dictionary) -> void:
	hint.touch()
	for t in page_view.tappables:
		t.show_hint(false)
	if def.has("flag"):
		state.set_flag(def["flag"])
		Store.set_resume(data.id, state.to_dict())


func _set_taps_locked(on: bool) -> void:
	if page_view:
		for t in page_view.tappables:
			t.locked = on


func _update_controls() -> void:
	controls.set_step(state.step(), data.path_length())
	controls.back_button.disabled = false
	controls.next_button.disabled = state.kind() != &"next"


func _set_text(highlight: int) -> void:
	_words = data.text(state.current, Store.level()).split(" ", false)
	var parts: PackedStringArray = []
	for i in _words.size():
		var w := _words[i].replace("[", "[lb]")
		parts.append("[color=#%s]%s[/color]" % [UiTheme.HIGHLIGHT.to_html(false), w] if i == highlight else w)
	text_label.text = " ".join(parts)


func _highlight(index: int) -> void:
	_set_text(index)


func _apply_safe_area() -> void:
	controls.apply_safe_area(SafeArea.current(get_viewport()))


func _gui_input(event: InputEvent) -> void:
	if Store.setting("turn_mode") != "swipe":
		return
	var pos := Vector2.ZERO
	var pressed := false
	if event is InputEventScreenTouch:
		pos = event.position
		pressed = event.pressed
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		pos = event.position
		pressed = event.pressed
	else:
		return
	if pressed:
		_swipe.begin(pos)
		return
	match _swipe.end(pos):
		&"next":
			next()
		&"back":
			handle_back()
