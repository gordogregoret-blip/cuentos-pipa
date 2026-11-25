class_name Levels
extends RefCounted
## Nivel de texto sugerido según la edad: 3-5 simple, 6-8 cuento, 9-12 aventura.

const ALL: Array[StringName] = [&"simple", &"cuento", &"aventura"]
const MIN_AGE := 3
const MAX_AGE := 12


static func for_age(age: int) -> StringName:
	if age <= 5:
		return &"simple"
	if age <= 8:
		return &"cuento"
	return &"aventura"
