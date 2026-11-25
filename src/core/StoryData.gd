class_name StoryData
extends RefCounted
## Un cuento cargado desde `<dir>/story.json` (ver docs/story-schema.md).
## Solo lectura: la navegación vive en StoryState.

var dir: String
var id: String
var title: String
var message: String
var start: String
var cast: Array = []
var preview: bool = false
var secret: Dictionary = {}
var pages: Dictionary = {}
var raw: Dictionary = {}


## Devuelve null si el archivo no existe o no es un cuento válido.
static func load_from(story_dir: String) -> StoryData:
	var path := story_dir.path_join("story.json")
	if not FileAccess.file_exists(path):
		return null
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary or not parsed.has("pages") or not parsed.has("start"):
		return null
	var d := StoryData.new()
	d.dir = story_dir
	d.raw = parsed
	d.id = parsed.get("id", "")
	d.title = parsed.get("title", "")
	d.message = parsed.get("message", "")
	d.start = parsed["start"]
	d.cast = parsed.get("cast", [])
	d.preview = parsed.get("preview", false)
	d.secret = parsed.get("secret", {})
	d.pages = parsed["pages"]
	return d


func has_page(page_id: String) -> bool:
	return pages.has(page_id)


func page(page_id: String) -> Dictionary:
	return pages.get(page_id, {})


func text(page_id: String, level: StringName) -> String:
	return page(page_id).get("text", {}).get(String(level), "")


func asset(rel: String) -> String:
	return dir.path_join(rel)


func vo_path(page_id: String, level: StringName) -> String:
	return asset("vo/%s_%s.ogg" % [page_id, level])


func timings_path(page_id: String, level: StringName) -> String:
	return asset("vo/%s_%s.json" % [page_id, level])


func tap_vo_path(page_id: String, tap_id: String) -> String:
	return asset("vo/%s_tap_%s.ogg" % [page_id, tap_id])


func option_vo_path(page_id: String, index: int) -> String:
	return asset("vo/%s_opt%d.ogg" % [page_id, index + 1])


func title_vo_path() -> String:
	return asset("vo/title.ogg")


func message_vo_path() -> String:
	return asset("vo/message.ogg")


## Ids de todos los finales (para las estrellas de la plaza).
func ending_ids() -> Array[String]:
	var out: Array[String] = []
	for pid in pages:
		var e: Dictionary = pages[pid].get("ending", {})
		if e.has("id"):
			out.append(e["id"])
	return out


## Páginas del recorrido más largo (para el indicador "3 de 7").
func path_length() -> int:
	var memo := {}
	return _depth(start, memo)


func _depth(pid: String, memo: Dictionary) -> int:
	if memo.has(pid):
		return memo[pid]
	memo[pid] = 1  # corta ciclos (el validador ya los rechaza)
	var p := page(pid)
	var best := 0
	var dests: Array = []
	if p.get("next") != null and p.has("next"):
		dests.append(p["next"])
	if p.has("secret_next"):
		dests.append(p["secret_next"])
	for o in p.get("decision", {}).get("options", []):
		dests.append(o["to"])
	for d in dests:
		if has_page(d):
			best = maxi(best, _depth(d, memo))
	memo[pid] = 1 + best
	return memo[pid]
