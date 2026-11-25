extends SceneTree
## Rasteriza los íconos de la app desde SVG (no usa autoloads).
## godot --headless --path . -s tools/store_assets/make_icons.gd


func _initialize() -> void:
	_svg("res://icon.svg", 192, "res://store/icon/icon_192.png")
	_svg("res://icon.svg", 512, "res://store/icon/icon_512.png")
	_svg("res://store/icon/icon_fg.svg", 432, "res://store/icon/adaptive_fg_432.png")
	var bg := Image.create(432, 432, false, Image.FORMAT_RGBA8)
	bg.fill(Color("#D9EEE4"))
	bg.save_png(ProjectSettings.globalize_path("res://store/icon/adaptive_bg_432.png"))
	print("íconos listos")
	quit()


func _svg(src: String, px: int, out: String) -> void:
	var text := FileAccess.get_file_as_string(src)
	var probe := Image.new()
	probe.load_svg_from_string(text, 1.0)
	var img := Image.new()
	img.load_svg_from_string(text, float(px) / probe.get_width())
	if img.get_width() != px:
		img.resize(px, px, Image.INTERPOLATE_LANCZOS)
	img.save_png(ProjectSettings.globalize_path(out))
