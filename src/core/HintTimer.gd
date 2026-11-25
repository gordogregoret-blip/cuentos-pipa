class_name HintTimer
extends RefCounted
## Cuenta el tiempo sin tocar nada. Dispara una vez; tocar algo lo reinicia.

var seconds: float
var _elapsed: float = 0.0
var _fired: bool = false


func _init(wait: float = 6.0) -> void:
	seconds = wait


func tick(dt: float) -> bool:
	if _fired:
		return false
	_elapsed += dt
	if _elapsed >= seconds - 0.0001:
		_fired = true
		return true
	return false


func touch() -> void:
	_elapsed = 0.0
	_fired = false
