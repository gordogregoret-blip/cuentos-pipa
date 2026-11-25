class_name Main
extends Control
## Punto de entrada: primer uso → plaza → portada → cuento, y las capas
## (calma, puerta para padres, panel) apiladas encima.
## El botón Atrás de Android nunca cierra la app de golpe.

@export var index_path: String = StoryIndex.DEFAULT
@export var quit_on_confirm: bool = true

var index: StoryIndex
var current: Control
var _screen: Control
var _overlays: Control


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = UiTheme.build(Store.setting("easy_font"))
	Motion.reduced = Store.setting("calm")
	_screen = Control.new()
	_screen.name = "Screen"
	_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_screen)
	_overlays = Control.new()
	_overlays.name = "Overlays"
	_overlays.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlays.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlays)
	index = StoryIndex.load_from(index_path)
	if Store.has_age():
		show_library()
	else:
		show_first_run()


func show_first_run() -> void:
	var f := FirstRun.new()
	f.done.connect(show_library)
	_set_screen(f)


func show_library() -> void:
	var lib := Library.new()
	_set_screen(lib)
	lib.build(index)
	lib.story_chosen.connect(_on_story_chosen)
	lib.adult_button.pressed.connect(open_adult)
	Audio.play_music("res://audio/music/plaza.ogg")


func open_story(id: String, resume: Dictionary = {}) -> void:
	var p: StoryPlayer = load("res://src/ui/StoryPlayer.tscn").instantiate()
	_set_screen(p)
	p.open(index.dir_for(id), resume)
	p.exit_requested.connect(_on_story_exit)
	p.controls.calm_pressed.connect(open_calm)


func open_overlay(node: Control) -> void:
	_overlays.add_child(node)
	_overlays.mouse_filter = Control.MOUSE_FILTER_STOP
	if node is Overlay:
		(node as Overlay).close_requested.connect(close_overlay.bind(node))


func close_overlay(node: Control = null) -> void:
	var target := node if node else top_overlay()
	if target == null:
		return
	_overlays.remove_child(target)
	target.queue_free()
	if _overlays.get_child_count() == 0:
		_overlays.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if target.has_method("on_closed"):
		target.on_closed()


func top_overlay() -> Control:
	var n := _overlays.get_child_count()
	return _overlays.get_child(n - 1) as Control if n > 0 else null


## Atrás: primero cierra la capa de arriba; si no hay, la pantalla decide.
func handle_back() -> void:
	var top := top_overlay()
	if top:
		if top.has_method("handle_back") and top.handle_back():
			return
		close_overlay()
		return
	if current is StoryPlayer:
		(current as StoryPlayer).handle_back()
	elif current is Library:
		var c := ConfirmExit.new()
		c.confirmed.connect(_quit)
		open_overlay(c)
	# En el primer uso, Atrás no hace nada: hay que elegir la edad.


func open_calm() -> void:
	var p := current as StoryPlayer
	if p:
		p.hold()
	Audio.stop_all()
	var c := CalmCorner.new()
	c.tree_exited.connect(func() -> void:
		if is_instance_valid(p) and p == current:
			p.resume_after_hold())
	open_overlay(c)


func open_adult() -> void:
	var gate := ParentGate.new()
	gate.passed.connect(func() -> void:
		close_overlay(gate)
		var panel := AdultPanel.new()
		panel.index = index
		panel.settings_changed.connect(_apply_settings)
		panel.tree_exited.connect(_apply_settings)
		open_overlay(panel))
	open_overlay(gate)


func _apply_settings() -> void:
	if not is_inside_tree():
		return
	theme = UiTheme.build(Store.setting("easy_font"))
	Motion.reduced = Store.setting("calm")
	Audio.apply_settings()
	if current is Library:
		(current as Library).refresh()
	elif current is StoryPlayer:
		(current as StoryPlayer).refresh_settings()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		handle_back()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		handle_back()
		get_viewport().set_input_as_handled()


func _on_story_chosen(id: String) -> void:
	var data := StoryData.load_from(index.dir_for(id))
	if data == null:
		return
	var cover := Cover.new()
	var resume := Store.resume_for(id)
	cover.setup(data, resume)
	cover.start.connect(func() -> void:
		close_overlay(cover)
		Store.clear_resume(id)
		open_story(id))
	cover.resume_story.connect(func() -> void:
		close_overlay(cover)
		open_story(id, resume))
	open_overlay(cover)


func _on_story_exit() -> void:
	Audio.stop_all()
	show_library()


func _set_screen(node: Control) -> void:
	while top_overlay():
		close_overlay()
	if current:
		_screen.remove_child(current)
		current.queue_free()
	current = node
	_screen.add_child(node)


func _quit() -> void:
	if quit_on_confirm:
		get_tree().quit()
	else:
		close_overlay()
