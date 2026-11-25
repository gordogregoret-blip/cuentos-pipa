extends Node
## Autoload "Store": dueño de los datos guardados. Toda escritura pasa por acá
## y se guarda enseguida (atómica), así nada se pierde si la app se cierra.

signal changed

var save_path := "user://save.json"
var data: Dictionary = SaveData.defaults()


func _ready() -> void:
	load_now()
	apply_locale()


func apply_locale() -> void:
	TranslationServer.set_locale(String(setting("locale")))


func load_now() -> void:
	data = SaveData.read(save_path)


func save() -> void:
	SaveData.write_atomic(save_path, data)
	changed.emit()


func setting(key: String) -> Variant:
	return data["settings"].get(key)


func set_setting(key: String, value: Variant) -> void:
	data["settings"][key] = value
	save()
	if key == "locale":
		apply_locale()


func set_age(age: int) -> void:
	data["age"] = clampi(age, Levels.MIN_AGE, Levels.MAX_AGE)
	save()


func has_age() -> bool:
	return int(data["age"]) > 0


func level() -> StringName:
	var chosen: String = setting("level")
	if chosen != "":
		return StringName(chosen)
	return Levels.for_age(int(data["age"]) if has_age() else 6)


func record_ending(story_id: String, ending_id: String) -> void:
	var list: Array = data["endings"].get(story_id, [])
	if not ending_id in list:
		list.append(ending_id)
		data["endings"][story_id] = list
		save()


func endings_for(story_id: String) -> Array:
	return data["endings"].get(story_id, [])


## true si la semilla es nueva.
func add_seed(story_id: String) -> bool:
	if story_id in data["seeds"]:
		return false
	data["seeds"].append(story_id)
	save()
	return true


func seed_count() -> int:
	return data["seeds"].size()


func set_resume(story_id: String, state: Dictionary) -> void:
	data["resume"][story_id] = state
	save()


func clear_resume(story_id: String) -> void:
	data["resume"].erase(story_id)
	save()


func resume_for(story_id: String) -> Dictionary:
	return data["resume"].get(story_id, {})


## "Borrar progreso": finales, semillas y reanudación. Ajustes y edad quedan.
func clear_progress() -> void:
	data["endings"] = {}
	data["seeds"] = []
	data["resume"] = {}
	save()
