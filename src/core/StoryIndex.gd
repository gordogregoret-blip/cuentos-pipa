class_name StoryIndex
extends RefCounted
## Las puertas de la plaza, leídas de stories/index.json.

const DEFAULT := "res://stories/index.json"

var path: String
var entries: Array = []  # [{id, title, door_color, locked}]


static func load_from(index_path: String = DEFAULT) -> StoryIndex:
	var idx := StoryIndex.new()
	idx.path = index_path
	if FileAccess.file_exists(index_path):
		var json := JSON.new()
		if json.parse(FileAccess.get_file_as_string(index_path)) == OK and json.data is Dictionary:
			idx.entries = json.data.get("stories", [])
	return idx


func dir_for(id: String) -> String:
	return path.get_base_dir().path_join(id)


func playable() -> Array:
	return entries.filter(func(e: Dictionary) -> bool: return not e.get("locked", false))


func entry(id: String) -> Dictionary:
	for e in entries:
		if e["id"] == id:
			return e
	return {}
