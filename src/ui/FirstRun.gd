class_name FirstRun
extends Control
## Primer uso: el adulto elige la edad (3 a 12) y se sugiere el nivel de texto.
## No se pide nombre ni ningún otro dato.

signal done

var level_label: Label
var start_button: Button
var age_buttons: Array[Button] = []
var _age: int = 0


func _init() -> void:
	name = "FirstRun"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := TextureRect.new()
	bg.texture = load("res://art/ui/plaza.svg")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(bg)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.custom_minimum_size = Vector2(1400, 0)
	add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 30)
	panel.add_child(col)
	col.add_child(Overlay.label(tr("FIRST_RUN_TITLE"), UiTheme.TITLE_SIZE))
	col.add_child(Overlay.label(tr("FIRST_RUN_AGE")))
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 24)
	var center := CenterContainer.new()
	center.add_child(grid)
	col.add_child(center)
	for age in range(Levels.MIN_AGE, Levels.MAX_AGE + 1):
		var b := Button.new()
		b.text = str(age)
		b.name = "Edad%d" % age
		b.custom_minimum_size = Vector2(150, 120)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 52)
		b.pressed.connect(pick_age.bind(age))
		grid.add_child(b)
		age_buttons.append(b)
	level_label = Overlay.label("")
	col.add_child(level_label)
	start_button = Overlay.text_button("BTN_START", "siguiente")
	start_button.disabled = true
	start_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start_button.pressed.connect(confirm)
	col.add_child(start_button)


func _ready() -> void:
	Audio.play_voice("res://audio/ui/first_run.ogg")


func pick_age(age: int) -> void:
	_age = age
	for b in age_buttons:
		b.modulate = Color.WHITE if b.text == str(age) else Color(1, 1, 1, 0.7)
	var level := Levels.for_age(age)
	level_label.text = tr("FIRST_RUN_LEVEL") % tr("LEVEL_" + String(level))
	start_button.disabled = false


func confirm() -> void:
	if _age == 0:
		return
	Store.set_setting("level", "")
	Store.set_age(_age)
	done.emit()
