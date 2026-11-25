class_name ParentGateLogic
extends RefCounted
## Puerta para padres: mantener apretado 3 s y después tocar 1, 2, 3 en orden.
## Equivocarse reinicia la secuencia en silencio (no hay "error" ni castigo).

const HOLD_SECONDS := 3.0

var state: StringName = &"hold"  # &"hold", &"order", &"open"
var numbers: Array = []  # 1, 2, 3 en el orden en que se muestran

var _held: float = 0.0
var _pressing: bool = false
var _next: int = 1


func press() -> void:
	if state == &"hold":
		_pressing = true


func release() -> void:
	_pressing = false
	if state == &"hold":
		_held = 0.0


func tick(dt: float) -> void:
	if state != &"hold" or not _pressing:
		return
	_held += dt
	if _held >= HOLD_SECONDS - 0.0001:
		state = &"order"
		_pressing = false
		numbers = [1, 2, 3]
		numbers.shuffle()
		_next = 1


func progress() -> float:
	return clampf(_held / HOLD_SECONDS, 0.0, 1.0)


func expected() -> int:
	return _next


## true cuando se completó la secuencia.
func tap(n: int) -> bool:
	if state != &"order":
		return false
	if n == _next:
		_next += 1
		if _next > 3:
			state = &"open"
			return true
	else:
		_next = 1
	return false
