class_name KaraokeTimeline
extends RefCounted
## Tiempos por palabra del relato: [{"w", "t0", "t1"}] en segundos del audio.

const EST_WORD_SECONDS := 0.45

var words: Array = []


func _init(timings: Array = []) -> void:
	words = timings


static func from_file(path: String, text: String) -> KaraokeTimeline:
	if FileAccess.file_exists(path):
		var json := JSON.new()
		if json.parse(FileAccess.get_file_as_string(path)) == OK and json.data is Array:
			return KaraokeTimeline.new(json.data)
	return estimated(text)


## Sin archivo de tiempos: cada palabra dura lo mismo.
static func estimated(text: String) -> KaraokeTimeline:
	var out: Array = []
	var t := 0.2
	for w in text.split(" ", false):
		out.append({"w": w, "t0": t, "t1": t + EST_WORD_SECONDS - 0.1})
		t += EST_WORD_SECONDS
	return KaraokeTimeline.new(out)


func size() -> int:
	return words.size()


## Índice de la palabra que se está diciendo en t (la última que empezó), o -1.
func index_at(t: float) -> int:
	var idx := -1
	for i in words.size():
		if float(words[i]["t0"]) <= t:
			idx = i
		else:
			break
	return idx


func end_time() -> float:
	return float(words[-1]["t1"]) if not words.is_empty() else 0.0
