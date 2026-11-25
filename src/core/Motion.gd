class_name Motion
extends RefCounted
## Movimiento global: en modo calma las animaciones se reducen.
## Reemplaza a `Juice` de Nido para el rig de personajes.

static var reduced: bool = false


static func enabled() -> bool:
	return not reduced


## Duración de una animación: con movimiento reducido pasa a ser instantánea.
static func duration(base_seconds: float) -> float:
	return 0.0 if reduced else base_seconds
