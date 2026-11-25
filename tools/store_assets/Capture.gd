extends Node
## Captura una pantalla de la app a PNG (para la ficha de Play y revisiones).
## xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1920x1080 \
##     res://tools/store_assets/Capture.tscn -- --scene story --story res://stories/dino \
##     --page p1 --out build/store/p1.png [--wait 1.5] [--level simple] [--age 6]

var _args := {}


func _ready() -> void:
	var raw := OS.get_cmdline_user_args()
	var i := 0
	while i < raw.size():
		if raw[i].begins_with("--") and i + 1 < raw.size():
			_args[raw[i].substr(2)] = raw[i + 1]
			i += 2
		else:
			i += 1
	Store.save_path = "user://capture_save.json"
	Store.data = SaveData.defaults()
	Store.data["age"] = int(_args.get("age", "6"))
	if _args.has("level"):
		Store.data["settings"]["level"] = _args["level"]
	for key in ["calm", "easy_font"]:
		if _args.has(key):
			Store.data["settings"][key] = _args[key] == "true"
	_run.call_deferred()


func _run() -> void:
	var node: Node = CaptureScenes.make(String(_args.get("scene", "story")), _args)
	get_tree().root.add_child(node)
	await get_tree().create_timer(float(_args.get("wait", "1.2"))).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var out := String(_args.get("out", "build/capture.png"))
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	img.save_png(out)
	print("captura: ", out, " ", img.get_size())
	get_tree().quit()
