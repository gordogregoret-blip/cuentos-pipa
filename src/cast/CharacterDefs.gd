class_name CharacterDefs
extends RefCounted
## Copiado de Nido (src/pueblo/kit/CharacterDefs.gd) y adaptado a Cuentos.
## Data for every cutout character: which SVG goes where, in what draw
## order, and which mouth goes with which state. Part names are uniform
## across characters (cuerpo, cabeza, ojo_*, boca, brazo_*, oreja_*,
## ceja_*) — Pipa's wings are her brazo_* — so scenes can say
## rig.get_part("brazo_der") without knowing who they're talking to.
##
## Offsets are each SVG's viewBox origin (the brief's pivot convention).
## They live here, not parsed at runtime, because exported builds ship
## only the imported textures; test_character_rig.gd checks them against
## the .svg files.

const P := "res://art/cast/"
const S := "res://art/cast/shared/"

const OFFSETS := {
	"pipa_cuerpo.svg": Vector2(-200, -410),
	"pipa_cabeza.svg": Vector2(-182, -300),
	"pipa_ala.svg": Vector2(-82, -20),
	"pipa_pico_abierto.svg": Vector2(-46, -32),
	"pipa_pico_cerrado.svg": Vector2(-46, -32),
	"pipa_pata.svg": Vector2(-48, -34),
	"coneja_cuerpo.svg": Vector2(-156, -352),
	"coneja_cabeza.svg": Vector2(-182, -266),
	"coneja_oreja.svg": Vector2(-56, -248),
	"coneja_brazo.svg": Vector2(-34, -26),
	"oso_cuerpo.svg": Vector2(-156, -352),
	"oso_cabeza.svg": Vector2(-182, -266),
	"oso_oreja.svg": Vector2(-56, -86),
	"oso_brazo.svg": Vector2(-34, -26),
	"perro_cuerpo.svg": Vector2(-156, -352),
	"perro_cabeza.svg": Vector2(-182, -266),
	"perro_oreja.svg": Vector2(-70, -14),
	"perro_brazo.svg": Vector2(-34, -26),
	"gato_cuerpo.svg": Vector2(-156, -352),
	"gato_cabeza.svg": Vector2(-182, -266),
	"gato_oreja.svg": Vector2(-56, -150),
	"gato_brazo.svg": Vector2(-34, -26),
	"ojo_abierto.svg": Vector2(-24, -30),
	"ojo_feliz.svg": Vector2(-30, -24),
	"boca_hablando.svg": Vector2(-26, -22),
	"boca_sonrisa.svg": Vector2(-30, -22),
	"boca_feliz.svg": Vector2(-32, -16),
	"boca_triste.svg": Vector2(-28, -16),
	"ceja.svg": Vector2(-28, -14),
}

## Nombre en los cuentos -> id del arte de Nido.
const CAST_IDS := {"pipa": "pipa", "sofi": "coneja", "bubu": "oso", "fido": "perro", "tati": "gato"}


static func offset_for(tex_path: String) -> Vector2:
	return OFFSETS.get(tex_path.get_file(), Vector2.ZERO)


static func get_def(id: String) -> Dictionary:
	match CAST_IDS.get(id, id):
		"pipa":
			return _pipa()
		"coneja":
			return _customer("coneja", Vector2(75, -235), 0.21, false, false, "orejas")
		"oso":
			return _customer("oso", Vector2(120, -205), 0.35, false, false, "bostezo")
		"perro":
			return _customer("perro", Vector2(150, -205), -0.12, true, true, "saltito")
		"gato":
			return _customer("gato", Vector2(105, -225), 0.32, false, false, "curioso")
	return {}


static func all_textures(id: String) -> Array[String]:
	var def := get_def(id)
	var out: Array[String] = []
	for part in def.get("parts", []):
		if part.get("tex", "") != "" and not part["tex"] in out:
			out.append(part["tex"])
	for tex in def.get("mouth", {}).values():
		if not tex in out:
			out.append(tex)
	if not S + "ojo_feliz.svg" in out:
		out.append(S + "ojo_feliz.svg")
	return out


static func _pipa() -> Dictionary:
	return {
		"parts": [
			{"name": "pata_izq", "tex": P + "pipa_pata.svg", "pos": Vector2(-80, 24)},
			{"name": "pata_der", "tex": P + "pipa_pata.svg", "pos": Vector2(80, 24), "mirror": true},
			{"name": "cuerpo", "tex": P + "pipa_cuerpo.svg"},
			{"name": "brazo_izq", "tex": P + "pipa_ala.svg", "pos": Vector2(-170, -260), "rot": 0.14},
			{"name": "brazo_der", "tex": P + "pipa_ala.svg", "pos": Vector2(170, -260), "rot": -0.14, "mirror": true},
			{"name": "cabeza", "pos": Vector2(0, -330)},
			{"name": "cabeza_sprite", "parent": "cabeza", "tex": P + "pipa_cabeza.svg"},
			{"name": "ojo_izq", "parent": "cabeza", "tex": S + "ojo_abierto.svg", "pos": Vector2(-62, -55)},
			{"name": "ojo_der", "parent": "cabeza", "tex": S + "ojo_abierto.svg", "pos": Vector2(62, -55)},
			{"name": "boca", "parent": "cabeza", "tex": P + "pipa_pico_cerrado.svg", "pos": Vector2(0, -5)},
		],
		"mouth": {
			"closed": P + "pipa_pico_cerrado.svg",
			"talk": P + "pipa_pico_abierto.svg",
			"happy": P + "pipa_pico_abierto.svg",
			"sad": P + "pipa_pico_cerrado.svg",
		},
		# Mirrored wing: a negative rotation swings it outward and up.
		"wave_up": -1.9,
		"quirk": "aletear",
		"shadow": Vector2(330, 44),
	}


## Customers share one skeleton; only the ears differ (position, tilt,
## whether the right one is a mirror, and whether they hang in front of the
## face like a dog's or stand behind the head like a bunny's).
static func _customer(prefix: String, ear_pos: Vector2, ear_rot: float, mirror_right: bool, ears_front: bool, quirk: String) -> Dictionary:
	var ears := [
		{"name": "oreja_izq", "parent": "cabeza", "tex": P + prefix + "_oreja.svg",
			"pos": Vector2(-ear_pos.x, ear_pos.y), "rot": -ear_rot},
		{"name": "oreja_der", "parent": "cabeza", "tex": P + prefix + "_oreja.svg",
			"pos": ear_pos, "rot": ear_rot, "mirror": mirror_right},
	]
	var parts: Array = [
		{"name": "brazo_izq", "tex": P + prefix + "_brazo.svg", "pos": Vector2(-135, -250), "rot": 0.26},
		{"name": "brazo_der", "tex": P + prefix + "_brazo.svg", "pos": Vector2(135, -250), "rot": -0.26},
		{"name": "cuerpo", "tex": P + prefix + "_cuerpo.svg"},
		{"name": "cabeza", "pos": Vector2(0, -310)},
	]
	if not ears_front:
		parts.append_array(ears)
	parts.append({"name": "cabeza_sprite", "parent": "cabeza", "tex": P + prefix + "_cabeza.svg"})
	if ears_front:
		parts.append_array(ears)
	parts.append_array([
		{"name": "ojo_izq", "parent": "cabeza", "tex": S + "ojo_abierto.svg", "pos": Vector2(-68, -135)},
		{"name": "ojo_der", "parent": "cabeza", "tex": S + "ojo_abierto.svg", "pos": Vector2(68, -135)},
		{"name": "ceja_izq", "parent": "cabeza", "tex": S + "ceja.svg", "pos": Vector2(-68, -184), "hidden": true},
		{"name": "ceja_der", "parent": "cabeza", "tex": S + "ceja.svg", "pos": Vector2(68, -184), "hidden": true},
		{"name": "boca", "parent": "cabeza", "tex": S + "boca_sonrisa.svg", "pos": Vector2(0, -42)},
	])
	return {
		"parts": parts,
		"mouth": {
			"closed": S + "boca_sonrisa.svg",
			"talk": S + "boca_hablando.svg",
			"happy": S + "boca_feliz.svg",
			"sad": S + "boca_triste.svg",
		},
		"wave_up": -2.6,
		"quirk": quirk,
		"shadow": Vector2(290, 40),
	}
