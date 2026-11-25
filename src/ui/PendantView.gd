class_name PendantView
extends Node2D
## El colgante dibujado: una piedra que cambia de color con un fundido suave
## (sin destellos) y su marco con contorno encima.

const GEM := preload("res://art/ui/colgante_gema.svg")
const FRAME := preload("res://art/ui/colgante.svg")

var gem: Sprite2D
var color_name: String = ""
var _tween: Tween


func _init() -> void:
	name = "Colgante"
	gem = Sprite2D.new()
	gem.texture = GEM
	gem.position = Vector2(0, 12)
	add_child(gem)
	var frame := Sprite2D.new()
	frame.texture = FRAME
	add_child(frame)


func set_color(c: String, animate: bool = true) -> void:
	if not Pendant.COLORS.has(c):
		return
	color_name = c
	var target: Color = Pendant.COLORS[c]
	if _tween and _tween.is_valid():
		_tween.kill()
	if not animate or not is_inside_tree():
		gem.modulate = target
		return
	_tween = create_tween()
	_tween.tween_property(gem, "modulate", target, Pendant.FADE).set_trans(Tween.TRANS_SINE)
