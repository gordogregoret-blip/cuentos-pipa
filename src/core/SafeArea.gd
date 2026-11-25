class_name SafeArea
extends RefCounted
## Márgenes para que los controles no queden bajo el notch o las barras.
## Se usa el mayor de cada par (izq/der) para que el diseño quede simétrico.


static func margins(safe: Rect2i, window: Vector2i) -> Dictionary:
	if safe.size.x <= 0 or safe.size.y <= 0:
		return {"left": 0, "top": 0, "right": 0, "bottom": 0}
	var left := safe.position.x
	var right := window.x - safe.end.x
	var top := safe.position.y
	var bottom := window.y - safe.end.y
	var side := maxi(maxi(left, right), 0)
	var vert := maxi(maxi(top, bottom), 0)
	return {"left": side, "top": vert if top > 0 else 0, "right": side, "bottom": vert if bottom > 0 else 0}


## Pasa márgenes de píxeles físicos a píxeles del lienzo (base 1920×1080).
static func to_canvas(m: Dictionary, scale: float) -> Dictionary:
	var out := {}
	for k in m:
		out[k] = float(m[k]) / scale
	return out


## Márgenes actuales del dispositivo, en coordenadas del lienzo.
static func current(viewport: Viewport) -> Dictionary:
	if not OS.has_feature("mobile"):
		return {"left": 0.0, "top": 0.0, "right": 0.0, "bottom": 0.0}
	var win := DisplayServer.window_get_size()
	var m := margins(DisplayServer.get_display_safe_area(), win)
	var visible := viewport.get_visible_rect().size
	var scale := float(win.y) / visible.y if visible.y > 0 else 1.0
	return to_canvas(m, maxf(scale, 0.001))
