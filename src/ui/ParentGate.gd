class_name ParentGate
extends Overlay
## Pantalla de la puerta para padres (ver ParentGateLogic).

signal passed

var logic := ParentGateLogic.new()
var number_buttons: Array[Button] = []
var hold_button: Button

var _col: VBoxContainer
var _title: Label
var _ring: ProgressBar
var _shown_state: StringName = &""


func _init() -> void:
	super()
	name = "ParentGate"
	add_shade(0.9)
	_col = add_column(1000)
	_title = Overlay.label("", 48)
	_col.add_child(_title)
	sync()


func _process(delta: float) -> void:
	logic.tick(delta)
	if _ring:
		_ring.value = logic.progress() * 100.0
	if logic.state != _shown_state:
		sync()


## Redibuja según el estado de la lógica.
func sync() -> void:
	_shown_state = logic.state
	for c in _col.get_children():
		if c != _title:
			c.queue_free()
	number_buttons.clear()
	_ring = null
	match logic.state:
		&"hold":
			_title.text = tr("GATE_HOLD")
			hold_button = UiTheme.icon_button("ajustes", "BTN_ADULT", 200)
			hold_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			hold_button.button_down.connect(logic.press)
			hold_button.button_up.connect(logic.release)
			_col.add_child(hold_button)
			_ring = ProgressBar.new()
			_ring.show_percentage = false
			_ring.custom_minimum_size = Vector2(500, 28)
			_ring.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			_col.add_child(_ring)
		&"order":
			_title.text = tr("GATE_ORDER")
			var r := Overlay.row()
			r.add_theme_constant_override("separation", 60)
			_col.add_child(r)
			for n in logic.numbers:
				var b := Button.new()
				b.text = str(n)
				b.custom_minimum_size = Vector2(180, 180)
				b.focus_mode = Control.FOCUS_NONE
				b.add_theme_font_size_override("font_size", 80)
				b.pressed.connect(_on_number.bind(n))
				r.add_child(b)
				number_buttons.append(b)
		&"open":
			passed.emit()
	var close := Overlay.text_button("ADULT_CLOSE", "no", 300)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.pressed.connect(func() -> void: close_requested.emit())
	_col.add_child(close)


func _on_number(n: int) -> void:
	if logic.tap(n):
		sync()
