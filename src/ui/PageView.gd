class_name PageView
extends Control
## Una página armada a partir de story.json: fondo, personajes y tocables.
## Las posiciones x, y del JSON son fracciones del tamaño de la página.

signal tapped(def: Dictionary)

var page_id: String
var data: StoryData
var characters: Dictionary = {}  # id -> nodo (CharacterRig o Sprite2D)
var tappables: Array = []
var pipa: CharacterRig
var pendant: PendantView


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	clip_contents = true


func build(story: StoryData, pid: String) -> void:
	data = story
	page_id = pid
	name = "Page_" + pid
	var p := story.page(pid)
	var bg := TextureRect.new()
	bg.name = "Fondo"
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.texture = _tex(p.get("background", ""))
	add_child(bg)
	for ch in p.get("characters", []):
		_add_character(ch)
	for def in p.get("tappables", []):
		_add_tappable(def)
	resized.connect(_layout)
	_layout.call_deferred()


func _add_character(ch: Dictionary) -> void:
	var node: Node2D
	var id: String = ch["id"]
	if CharacterDefs.CAST_IDS.has(id):
		var rig := CharacterRig.new()
		rig.character_id = id
		node = rig
		if id == "pipa":
			pipa = rig
			pendant = PendantView.new()
			pendant.position = Vector2(0, -150)
			pendant.scale = Vector2(1.3, 1.3)
			# El rig arma sus piezas en _ready: el colgante va después, encima del cuerpo.
			rig.ready.connect(rig.add_child.bind(pendant), CONNECT_ONE_SHOT)
	else:
		var s := Sprite2D.new()
		s.texture = _tex(id)
		s.offset = Vector2(0, -s.texture.get_height() / 2.0) if s.texture else Vector2.ZERO
		node = s
	node.name = id.get_file().get_basename()
	node.set_meta("fx", float(ch["x"]))
	node.set_meta("fy", float(ch["y"]))
	var sc: float = ch.get("scale", 0.5)
	node.scale = Vector2(-sc if ch.get("flip", false) else sc, sc)
	add_child(node)
	characters[id] = node
	if node is CharacterRig and ch.has("state"):
		(node as CharacterRig).set_state.call_deferred(StringName(ch["state"]))


## Color del colgante; con animate cambia con fundido y Pipa pone la cara de esa emoción.
func set_pendant(color: String, animate: bool = false) -> void:
	if pendant:
		pendant.set_color(color, animate)
	if pipa and animate:
		pipa.set_state(Pendant.rig_state(color))


func _add_tappable(def: Dictionary) -> void:
	var t := Tappable.new()
	t.setup(def, data, page_id)
	t.tapped.connect(func(d: Dictionary) -> void: tapped.emit(d))
	add_child(t)
	tappables.append(t)


func _layout() -> void:
	for n in get_children():
		if n is Node2D and n.has_meta("fx"):
			n.position = Vector2(n.get_meta("fx") * size.x, n.get_meta("fy") * size.y)
		elif n is Tappable:
			(n as Tappable).place_in(size)


func _tex(rel: String) -> Texture2D:
	if rel == "":
		return null
	var path := data.asset(rel)
	return load(path) as Texture2D if ResourceLoader.exists(path) else null
