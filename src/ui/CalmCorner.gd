class_name CalmCorner
extends Overlay
## Rincón de calma: todo se detiene y Lumi respira (inflar 4 s / desinflar 4 s)
## con la voz guiando. Botón "Volver al cuento".

var lumi: TextureRect
var guide_label: Label
var back_button: Button
var t: float = 0.0

var _phase: StringName = &""


func _init() -> void:
	super()
	name = "CalmCorner"
	var bg := ColorRect.new()
	bg.color = Color("#CFE3EE")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var title := Overlay.label(tr("CALM_TITLE"), 56)
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.grow_horizontal = Control.GROW_DIRECTION_BOTH
	title.offset_top = 60
	title.offset_left = -800
	title.offset_right = 800
	add_child(title)
	lumi = TextureRect.new()
	lumi.texture = load("res://art/ui/lumi.svg")
	lumi.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	lumi.custom_minimum_size = Vector2(380, 380)
	lumi.size = lumi.custom_minimum_size
	lumi.set_anchors_preset(Control.PRESET_CENTER)
	lumi.position = -lumi.size / 2.0 + Vector2(0, -40)
	lumi.pivot_offset = lumi.size / 2.0
	add_child(lumi)
	guide_label = Overlay.label("", 52)
	guide_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	guide_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	guide_label.offset_top = -280
	guide_label.offset_bottom = -200
	guide_label.offset_left = -800
	guide_label.offset_right = 800
	add_child(guide_label)
	back_button = Overlay.text_button("BTN_BACK_TO_STORY", "atras", 460)
	back_button.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	back_button.grow_horizontal = Control.GROW_DIRECTION_BOTH
	back_button.offset_top = -170
	back_button.offset_bottom = -54
	back_button.pressed.connect(func() -> void: close_requested.emit())
	add_child(back_button)


func _ready() -> void:
	Audio.play_voice("res://audio/ui/calm_intro.ogg")
	advance(0.0)


func _process(delta: float) -> void:
	advance(delta)


func advance(dt: float) -> void:
	if Audio.paused:
		return
	t += dt
	lumi.scale = Vector2.ONE * BreathCycle.scale_at(t)
	var ph := BreathCycle.phase_at(t)
	if ph != _phase:
		_phase = ph
		guide_label.text = tr("CALM_IN") if ph == &"in" else tr("CALM_OUT")
		if t > 0.5:
			Audio.play_voice("res://audio/ui/calm_%s.ogg" % ph)
