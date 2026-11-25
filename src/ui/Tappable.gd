class_name Tappable
extends Control
## Algo que reacciona al tocarlo: animación suave + efecto + palabra dicha.
## Nunca destella ni vibra. Puede activar una marca (huella del secreto).

signal tapped(def: Dictionary)

const MIN_SIZE := 96.0
const LUMI := preload("res://art/ui/lumi.svg")

var def: Dictionary
var locked: bool = false
var rig: CharacterRig
var word_vo: String
var sfx: String
var times_tapped: int = 0

var _art: Control
var _hint: TextureRect
var _hint_tween: Tween
var _anim: Tween


func setup(d: Dictionary, data: StoryData, page_id: String) -> void:
	def = d
	name = "Tap_" + String(d["id"])
	sfx = data.asset(d["sfx"])
	word_vo = data.tap_vo_path(page_id, d["id"])
	var side := maxf(float(d.get("size", MIN_SIZE)), MIN_SIZE)
	custom_minimum_size = Vector2(side, side)
	size = custom_minimum_size
	pivot_offset = size / 2.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	var art: String = d["art"]
	if art.begins_with("cast:"):
		var holder := Control.new()
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.set_anchors_preset(Control.PRESET_FULL_RECT)
		rig = CharacterRig.new()
		rig.character_id = art.substr(5)
		var sc := side / 780.0
		rig.scale = Vector2(sc, sc)
		rig.position = Vector2(side / 2.0, side)
		holder.add_child(rig)
		_art = holder
	else:
		var tr := TextureRect.new()
		tr.set_anchors_preset(Control.PRESET_FULL_RECT)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var path := data.asset(art)
		tr.texture = load(path) if ResourceLoader.exists(path) else null
		_art = tr
	add_child(_art)
	_hint = TextureRect.new()
	_hint.texture = LUMI
	_hint.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_hint.custom_minimum_size = Vector2(110, 110)
	_hint.size = Vector2(110, 110)
	_hint.position = Vector2(side - 70.0, -50.0)
	_hint.pivot_offset = Vector2(55, 55)
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint.visible = false
	add_child(_hint)


func place_in(page_size: Vector2) -> void:
	position = Vector2(def["x"] * page_size.x, def["y"] * page_size.y) - size / 2.0


func _gui_input(event: InputEvent) -> void:
	var pressed: bool = (event is InputEventScreenTouch and event.pressed) \
		or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	if pressed and tap():
		accept_event()


## true si reaccionó.
func tap() -> bool:
	if locked:
		return false
	times_tapped += 1
	show_hint(false)
	_play_anim(String(def.get("anim", "bounce")))
	Audio.play_sfx(sfx)
	var delay := 0.35
	if is_inside_tree():
		get_tree().create_timer(delay).timeout.connect(Audio.play_sfx.bind(word_vo))
	if rig:
		rig.set_state(&"contento")
	tapped.emit(def)
	return true


## Lumi se posa sobre el tocable y brilla despacio (sin parpadeo).
func show_hint(on: bool) -> void:
	_hint.visible = on
	if _hint_tween and _hint_tween.is_valid():
		_hint_tween.kill()
	if on and is_inside_tree():
		_hint.scale = Vector2.ONE
		_hint_tween = create_tween().set_loops()
		_hint_tween.tween_property(_hint, "scale", Vector2(1.12, 1.12), 1.2).set_trans(Tween.TRANS_SINE)
		_hint_tween.tween_property(_hint, "scale", Vector2.ONE, 1.2).set_trans(Tween.TRANS_SINE)


func hint_visible() -> bool:
	return _hint.visible


func _play_anim(kind: String) -> void:
	if not is_inside_tree():
		return
	if _anim and _anim.is_valid():
		_anim.kill()
	scale = Vector2.ONE
	rotation = 0.0
	var k := 0.5 if Motion.reduced else 1.0
	var base_y := position.y
	_anim = create_tween()
	match kind:
		"wiggle":
			for a in [0.14, -0.14, 0.08, 0.0]:
				_anim.tween_property(self, "rotation", a * k, 0.09).set_trans(Tween.TRANS_SINE)
		"hop":
			_anim.tween_property(self, "position:y", base_y - 50.0 * k, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			_anim.tween_property(self, "position:y", base_y, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		"spin":
			_anim.tween_property(self, "rotation", TAU, 0.6 if k == 1.0 else 0.0).set_trans(Tween.TRANS_SINE)
			_anim.tween_callback(func() -> void: rotation = 0.0)
		"grow":
			_anim.tween_property(self, "scale", Vector2.ONE * (1.0 + 0.18 * k), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			_anim.tween_property(self, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_SINE)
		"float":
			_anim.tween_property(self, "position:y", base_y - 40.0 * k, 0.4).set_trans(Tween.TRANS_SINE)
			_anim.tween_property(self, "position:y", base_y, 0.4).set_trans(Tween.TRANS_SINE)
		_:
			_anim.tween_property(self, "scale", Vector2(1.0 + 0.08 * k, 1.0 - 0.08 * k), 0.1)
			_anim.tween_property(self, "scale", Vector2(1.0 - 0.05 * k, 1.0 + 0.1 * k), 0.12)
			_anim.tween_property(self, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
