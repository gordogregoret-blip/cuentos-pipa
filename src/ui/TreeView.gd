class_name TreeView
extends Control
## El Árbol de las Puertas con sus semillas de luz. Con 7, florece.

const SLOTS := [Vector2(450, 140), Vector2(300, 250), Vector2(600, 250), Vector2(190, 400),
	Vector2(710, 400), Vector2(360, 420), Vector2(540, 420)]
const BLOOM_AT := 7

var seeds_shown: int = 0
var bloomed: bool = false

var _marks: Array[Control] = []


func _init() -> void:
	name = "Arbol"
	custom_minimum_size = Vector2(900, 1000)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var t := TextureRect.new()
	t.texture = load("res://art/ui/arbol.svg")
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.set_anchors_preset(Control.PRESET_FULL_RECT)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(t)


func set_seeds(n: int) -> void:
	for m in _marks:
		m.queue_free()
	_marks.clear()
	seeds_shown = mini(n, SLOTS.size())
	bloomed = n >= BLOOM_AT
	for i in seeds_shown:
		_mark("res://art/ui/semilla.svg", SLOTS[i], 96.0)
	if bloomed:
		for p in [Vector2(250, 180), Vector2(650, 160), Vector2(450, 300), Vector2(150, 330), Vector2(760, 330)]:
			_mark("res://art/ui/flor.svg", p, 70.0)


func _mark(path: String, center: Vector2, side: float) -> void:
	var r := TextureRect.new()
	r.texture = load(path)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.size = Vector2(side, side)
	r.position = center - r.size / 2.0
	r.pivot_offset = r.size / 2.0
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)
	_marks.append(r)
	if is_inside_tree() and not Motion.reduced:
		var tw := create_tween().set_loops()
		tw.tween_property(r, "scale", Vector2(1.08, 1.08), 1.6).set_trans(Tween.TRANS_SINE)
		tw.tween_property(r, "scale", Vector2.ONE, 1.6).set_trans(Tween.TRANS_SINE)
