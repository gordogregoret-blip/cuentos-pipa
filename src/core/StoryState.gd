class_name StoryState
extends RefCounted
## Dónde está el chico dentro de un cuento: página actual, camino recorrido
## (para Atrás) y marcas activadas (huellas del final secreto).

var data: StoryData
var current: String = ""
var history: Array[String] = []
var flags: Array[String] = []


func _init(story: StoryData) -> void:
	data = story


func start() -> void:
	current = data.start
	history.clear()
	flags.clear()


func page() -> Dictionary:
	return data.page(current)


## &"next", &"decision", &"closing" o &"end_preview" (cuento de prueba sin seguir).
func kind() -> StringName:
	var p := page()
	if p.has("decision"):
		return &"decision"
	if p.get("closing", false):
		return &"closing"
	if p.get("next") == null:
		return &"end_preview"
	return &"next"


## Número de página dentro del recorrido (1 a 7).
func step() -> int:
	return history.size() + 1


func ending() -> Dictionary:
	return page().get("ending", {})


func go_next() -> bool:
	if kind() != &"next":
		return false
	var p := page()
	var dest: String = p["next"]
	if p.has("secret_next") and has_all_secret_flags():
		dest = p["secret_next"]
	_go(dest)
	return true


func choose(index: int) -> bool:
	if kind() != &"decision":
		return false
	var options: Array = page()["decision"]["options"]
	if index < 0 or index >= options.size():
		return false
	_go(options[index]["to"])
	return true


func back() -> bool:
	if history.is_empty():
		return false
	current = history.pop_back()
	return true


func set_flag(flag: String) -> void:
	if flag != "" and not flag in flags:
		flags.append(flag)


func has_all_secret_flags() -> bool:
	for f in data.secret.get("requires", []):
		if not f in flags:
			return false
	return not data.secret.is_empty()


## "Probar otro camino": vuelve a la última decisión del recorrido.
func rewind_to_last_decision() -> bool:
	for i in range(history.size() - 1, -1, -1):
		if data.page(history[i]).has("decision"):
			current = history[i]
			history = history.slice(0, i)
			return true
	return false


func to_dict() -> Dictionary:
	return {"page": current, "history": history.duplicate(), "flags": flags.duplicate()}


## false (y sin cambios) si la reanudación apunta a páginas que no existen.
func from_dict(d: Dictionary) -> bool:
	var pid: String = d.get("page", "")
	if not data.has_page(pid):
		return false
	var hist: Array[String] = []
	for h in d.get("history", []):
		if not data.has_page(String(h)):
			return false
		hist.append(String(h))
	var fl: Array[String] = []
	for f in d.get("flags", []):
		fl.append(String(f))
	current = pid
	history = hist
	flags = fl
	return true


func _go(dest: String) -> void:
	history.append(current)
	current = dest
