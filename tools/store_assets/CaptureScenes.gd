class_name CaptureScenes
extends RefCounted
## Arma la pantalla pedida para tools/store_assets/Capture.tscn.
## Escenas: story, library, firstrun, calm, adult, gate, closing, feature.


static func make(kind: String, args: Dictionary) -> Node:
	var story_dir := String(args.get("story", "res://stories/dino"))
	match kind:
		"story", "closing":
			var p: Control = load("res://src/ui/StoryPlayer.tscn").instantiate()
			p.ready.connect(func() -> void:
				var resume := {}
				if args.has("page"):
					resume = {"page": args["page"], "history": _history(args), "flags": []}
				(p as StoryPlayer).open(story_dir, resume)
				if kind == "closing":
					(p as StoryPlayer).closing.show_closing((p as StoryPlayer).data)
				if args.has("hint"):
					(p as StoryPlayer).page_view.tappables[int(args["hint"])].show_hint(true)
				if args.has("cards"):
					(p as StoryPlayer).decision_cards.show_options((p as StoryPlayer).data, args["page"]))
			return p
		"library", "firstrun", "calm", "adult", "gate":
			var m: Main = load("res://src/Main.tscn").instantiate()
			if kind == "firstrun":
				Store.data["age"] = 0
			if args.has("seeds"):
				for i in int(args["seeds"]):
					Store.data["seeds"].append("s%d" % i)
			if args.has("endings"):
				Store.data["endings"]["dino"] = String(args["endings"]).split(",")
			m.ready.connect(func() -> void:
				match kind:
					"calm":
						m.open_story("dino", {"page": "b3", "history": ["p1", "p2"], "flags": []})
						m.open_calm()
					"gate":
						m.open_adult()
					"adult":
						var panel := AdultPanel.new()
						panel.index = m.index
						m.open_overlay(panel))
			return m
		"feature":
			return _feature()
	push_error("escena desconocida: " + kind)
	return Node.new()


## Gráfico destacado (1024×500): la plaza, el árbol, Pipa y el título.
static func _feature() -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = UiTheme.build(false)
	var bg := TextureRect.new()
	bg.texture = load("res://art/ui/plaza.svg")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	root.add_child(bg)
	var tree := TreeView.new()
	tree.position = Vector2(1080, 60)
	tree.scale = Vector2(0.95, 0.95)
	tree.set_seeds(3)
	root.add_child(tree)
	var pipa := CharacterRig.new()
	pipa.character_id = "pipa"
	pipa.position = Vector2(520, 930)
	pipa.scale = Vector2(0.75, 0.75)
	root.add_child(pipa)
	pipa.set_state.call_deferred(&"saludar")
	var fido := CharacterRig.new()
	fido.character_id = "fido"
	fido.position = Vector2(860, 960)
	fido.scale = Vector2(0.6, 0.6)
	root.add_child(fido)
	var title := Label.new()
	title.text = "Cuentos de Pipa"
	title.add_theme_font_size_override("font_size", 150)
	title.add_theme_color_override("font_color", UiTheme.INK)
	title.add_theme_color_override("font_outline_color", UiTheme.CREAM)
	title.add_theme_constant_override("outline_size", 36)
	title.position = Vector2(90, 70)
	root.add_child(title)
	return root


static func _history(args: Dictionary) -> Array:
	var h: Array = []
	for i in int(args.get("step", "1")) - 1:
		h.append("p1")
	return h
