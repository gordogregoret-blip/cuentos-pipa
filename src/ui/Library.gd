class_name Library
extends Control
## La plaza del pueblo con el Árbol de las Puertas. Cada puerta es un cuento.

signal story_chosen(id: String)

const DOOR_SLOTS := [Vector2(170, 300), Vector2(420, 300), Vector2(170, 640), Vector2(420, 640),
	Vector2(1300, 300), Vector2(1550, 300), Vector2(1300, 640), Vector2(1550, 640)]

var index: StoryIndex
var doors: Array[Door] = []
var tree: TreeView
var adult_button: Button


func _init() -> void:
	name = "Library"
	set_anchors_preset(Control.PRESET_FULL_RECT)


func build(idx: StoryIndex) -> void:
	index = idx
	for c in get_children():
		c.queue_free()
	doors.clear()
	var bg := TextureRect.new()
	bg.texture = load("res://art/ui/plaza.svg")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var stage := Control.new()  # 1920×1080 centrado: se ve igual en 4:3 y en 20:9
	stage.name = "Stage"
	stage.set_anchors_preset(Control.PRESET_CENTER)
	stage.size = Vector2(1920, 1080)
	stage.position = -stage.size / 2.0
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stage)
	tree = TreeView.new()
	tree.position = Vector2(510, 40)
	stage.add_child(tree)
	for i in mini(idx.entries.size(), DOOR_SLOTS.size()):
		var d := Door.new()
		d.setup(idx.entries[i])
		d.position = DOOR_SLOTS[i]
		d.opened.connect(_on_door_opened)
		stage.add_child(d)
		doors.append(d)
	adult_button = UiTheme.icon_button("ajustes", "BTN_ADULT", 104)
	adult_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	adult_button.offset_left = -136
	adult_button.offset_top = -136
	adult_button.offset_right = -32
	adult_button.offset_bottom = -32
	add_child(adult_button)
	refresh()


## Estrellas y semillas según lo guardado.
func refresh() -> void:
	for d in doors:
		var total := 0
		if not d.locked:
			var data := StoryData.load_from(index.dir_for(d.id))
			total = data.ending_ids().size() if data else 0
		d.set_stars(Store.endings_for(d.id).size(), total)
	tree.set_seeds(Store.seed_count())


func _on_door_opened(id: String) -> void:
	Audio.play_voice(index.dir_for(id).path_join("vo/title.ogg"))
	story_chosen.emit(id)
