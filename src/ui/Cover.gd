class_name Cover
extends Overlay
## Portada de anticipación: título, quiénes van y cuántas páginas tiene.
## Botones: Empezar, Seguir donde estaba (si hay progreso) y Volver a la plaza.

signal start
signal resume_story

var continue_button: Button
var start_button: Button
var _col: VBoxContainer


func _init() -> void:
	super()
	name = "Cover"
	add_shade(0.6)
	_col = add_column(1300)


func setup(data: StoryData, resume: Dictionary) -> void:
	for c in _col.get_children():
		c.queue_free()
	_col.add_child(Overlay.label(data.title, UiTheme.TITLE_SIZE))
	var cast := HBoxContainer.new()
	cast.alignment = BoxContainer.ALIGNMENT_CENTER
	cast.custom_minimum_size = Vector2(0, 300)
	cast.add_theme_constant_override("separation", 40)
	_col.add_child(cast)
	for id in data.cast:
		var slot := Control.new()
		slot.custom_minimum_size = Vector2(220, 300)
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if CharacterDefs.CAST_IDS.has(id):
			var rig := CharacterRig.new()
			rig.character_id = id
			rig.scale = Vector2(0.34, 0.34)
			rig.position = Vector2(110, 290)
			slot.add_child(rig)
		var name_label := Overlay.label(String(id).capitalize(), 36)
		name_label.position = Vector2(0, 300)
		name_label.size = Vector2(220, 50)
		slot.add_child(name_label)
		cast.add_child(slot)
	_col.add_child(Control.new())
	_col.get_child(-1).custom_minimum_size = Vector2(0, 50)
	_col.add_child(Overlay.label(tr("PAGE_OF") % [1, data.path_length()], 36))
	var r := Overlay.row()
	_col.add_child(r)
	var back := Overlay.text_button("BTN_PLAZA", "casa", 300)
	back.pressed.connect(func() -> void: close_requested.emit())
	r.add_child(back)
	continue_button = Overlay.text_button("BTN_CONTINUE", "repetir", 420)
	continue_button.pressed.connect(func() -> void: resume_story.emit())
	continue_button.visible = not resume.is_empty()
	r.add_child(continue_button)
	start_button = Overlay.text_button("BTN_START", "siguiente", 340)
	start_button.pressed.connect(func() -> void: start.emit())
	r.add_child(start_button)
