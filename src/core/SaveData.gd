class_name SaveData
extends RefCounted
## Formato de user://save.json: ajustes, edad, finales, semillas y reanudación.
## Todo queda en el dispositivo. Escritura atómica (archivo temporal + rename)
## y migración desde versiones anteriores del esquema.

const SCHEMA := 1


static func defaults() -> Dictionary:
	return {
		"schema": SCHEMA,
		"age": 0,  # 0 = todavía no se cargó (primer uso)
		"settings": {
			"level": "",  # "" = según la edad
			"vol_voz": 1.0,
			"vol_efectos": 0.7,
			"vol_musica": 0.4,
			"speed": 1.0,
			"calm": false,
			"subtitles": true,
			"lock_taps": false,
			"turn_mode": "button",  # "button" o "swipe"
			"easy_font": false,
			"locale": "es",
		},
		"endings": {},  # id de cuento -> [ids de final]
		"seeds": [],  # ids de cuento con semilla plantada
		"resume": {},  # id de cuento -> {page, history, flags}
	}


static func read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return defaults()
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK or not json.data is Dictionary:
		return defaults()
	return migrate(json.data)


static func migrate(d: Dictionary) -> Dictionary:
	var src := d.duplicate(true)
	if not src.has("schema"):
		src = _from_v0(src)
	return _sanitize(src)


static func write_atomic(path: String, d: Dictionary) -> bool:
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(d, "\t"))
	f.flush()
	f.close()
	var abs_tmp := ProjectSettings.globalize_path(tmp)
	var abs_path := ProjectSettings.globalize_path(path)
	if DirAccess.rename_absolute(abs_tmp, abs_path) != OK:
		DirAccess.remove_absolute(abs_path)
		if DirAccess.rename_absolute(abs_tmp, abs_path) != OK:
			return false
	return true


## v0: formato de las primeras pruebas (claves planas en castellano).
static func _from_v0(d: Dictionary) -> Dictionary:
	var out := defaults()
	if d.has("edad"):
		out["age"] = d["edad"]
	if d.has("volumen"):
		out["settings"]["vol_voz"] = d["volumen"]
	if d.has("finales"):
		out["endings"] = d["finales"]
	return out


## Completa lo que falta y descarta valores con tipo equivocado.
static func _sanitize(d: Dictionary) -> Dictionary:
	var out := defaults()
	for key in out:
		if key == "schema" or not d.has(key):
			continue
		if key == "settings" and d[key] is Dictionary:
			for sk in out["settings"]:
				if d["settings"].has(sk) and _same_type(d["settings"][sk], out["settings"][sk]):
					out["settings"][sk] = d["settings"][sk]
		elif _same_type(d[key], out[key]):
			out[key] = d[key]
	out["age"] = int(out["age"])
	return out


static func _same_type(a: Variant, b: Variant) -> bool:
	var ta := typeof(a)
	var tb := typeof(b)
	var numeric := [TYPE_INT, TYPE_FLOAT]
	return ta == tb or (ta in numeric and tb in numeric)
