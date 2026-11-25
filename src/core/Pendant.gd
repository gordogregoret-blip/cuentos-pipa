class_name Pendant
extends RefCounted
## El Colgante de los colores: color -> emoción de Pipa.

const FADE := 0.6

const COLORS := {
	"amarillo": Color("#FFD86B"),
	"azul": Color("#6FA8DC"),
	"rojo": Color("#E8806E"),
	"violeta": Color("#B38FD9"),
	"verde": Color("#7FC28E"),
	"naranja": Color("#F5A04A"),
}

const EMOTION := {
	"amarillo": "contenta",
	"azul": "triste",
	"rojo": "enojada",
	"violeta": "sorprendida",
	"verde": "tranquila",
	"naranja": "con miedo",
}

const RIG_STATE := {
	"amarillo": &"contento",
	"azul": &"triste",
	"rojo": &"pensar",
	"violeta": &"sorpresa",
	"verde": &"idle",
	"naranja": &"esperar",
}


## "El colgante está azul. Pipa está triste."
static func phrase(color: String) -> String:
	var emo: String = EMOTION.get(color, "")
	if color == "naranja":
		return "El colgante está naranja. Pipa tiene miedo."
	return "El colgante está %s. Pipa está %s." % [color, emo]


static func rig_state(color: String) -> StringName:
	return RIG_STATE.get(color, &"idle")


## Último color cuyo `at` ya pasó (fracción del relato), o "".
static func due(entries: Array, fraction: float) -> String:
	var out := ""
	for e in entries:
		if float(e["at"]) <= fraction:
			out = e["color"]
	return out
