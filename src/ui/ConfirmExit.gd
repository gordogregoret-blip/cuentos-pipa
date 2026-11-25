class_name ConfirmExit
extends Overlay
## "¿Salir?" con íconos: sí (tilde) / no (cruz). Nunca se cierra de golpe.

signal confirmed


func _init() -> void:
	super()
	name = "ConfirmExit"
	add_shade(0.7)
	var col := add_column(800)
	var door := TextureRect.new()
	door.texture = load("res://art/ui/casa.svg")
	door.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	door.custom_minimum_size = Vector2(140, 140)
	door.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(door)
	col.add_child(Overlay.label(tr("EXIT_QUESTION"), UiTheme.TITLE_SIZE))
	var r := Overlay.row()
	r.add_theme_constant_override("separation", 120)
	col.add_child(r)
	var no := UiTheme.icon_button("no", "BTN_NO", 150)
	no.pressed.connect(func() -> void: close_requested.emit())
	var yes := UiTheme.icon_button("si", "BTN_YES", 150)
	yes.pressed.connect(func() -> void: confirmed.emit())
	r.add_child(no)
	r.add_child(yes)


func _ready() -> void:
	Audio.play_voice("res://audio/ui/exit_question.ogg")
