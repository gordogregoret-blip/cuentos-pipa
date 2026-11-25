class_name SwipeDetector
extends RefCounted
## Deslizamiento horizontal para girar la hoja. Se ignoran los menores a 120 px
## y los que son más verticales que horizontales.

const MIN_DISTANCE := 120.0

var _start: Vector2
var _active: bool = false


func begin(pos: Vector2) -> void:
	_start = pos
	_active = true


## &"next" (hacia la izquierda), &"back" (hacia la derecha) o &"".
func end(pos: Vector2) -> StringName:
	if not _active:
		return &""
	_active = false
	var d := pos - _start
	if absf(d.x) < MIN_DISTANCE or absf(d.y) > absf(d.x):
		return &""
	return &"next" if d.x < 0.0 else &"back"
