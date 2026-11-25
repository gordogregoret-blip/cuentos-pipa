extends GutTest

const PATH := "user://test_save.json"
const StoreScript := preload("res://src/autoload/Store.gd")


func after_each() -> void:
	for p in [PATH, PATH + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)


func _write_raw(text: String) -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func _store() -> Node:
	var s: Node = StoreScript.new()
	s.save_path = PATH
	s.load_now()
	autofree(s)
	return s


func test_missing_file_gives_defaults() -> void:
	assert_eq(SaveData.read(PATH), SaveData.defaults())


func test_garbage_gives_defaults() -> void:
	_write_raw("{esto no es json")
	assert_eq(SaveData.read(PATH), SaveData.defaults())
	_write_raw("[1, 2, 3]")
	assert_eq(SaveData.read(PATH), SaveData.defaults())


func test_defaults_shape() -> void:
	var d := SaveData.defaults()
	assert_eq(d["schema"], SaveData.SCHEMA)
	assert_eq(d["age"], 0)
	assert_eq(d["settings"]["speed"], 1.0)
	assert_eq(d["settings"]["subtitles"], true)
	assert_eq(d["settings"]["turn_mode"], "button")
	assert_eq(d["seeds"], [])
	assert_eq(d["resume"], {})


func test_migrates_v0() -> void:
	var v0 := {"edad": 7, "volumen": 0.5, "finales": {"dino": ["rex"]}}
	var d := SaveData.migrate(v0)
	assert_eq(d["schema"], SaveData.SCHEMA)
	assert_eq(d["age"], 7)
	assert_eq(d["settings"]["vol_voz"], 0.5)
	assert_eq(d["endings"], {"dino": ["rex"]})


func test_migrate_fills_missing_and_fixes_types() -> void:
	var d := SaveData.migrate({"schema": 1, "age": "nueve", "settings": {"speed": 1.2}})
	assert_eq(d["age"], 0)
	assert_eq(d["settings"]["speed"], 1.2)
	assert_eq(d["settings"]["subtitles"], true)


func test_atomic_write_roundtrip() -> void:
	var d := SaveData.defaults()
	d["age"] = 6
	assert_true(SaveData.write_atomic(PATH, d))
	assert_false(FileAccess.file_exists(PATH + ".tmp"))
	assert_eq(SaveData.read(PATH)["age"], 6)
	d["age"] = 8
	assert_true(SaveData.write_atomic(PATH, d), "sobrescribe un archivo existente")
	assert_eq(SaveData.read(PATH)["age"], 8)


func test_store_endings_seeds_resume() -> void:
	var s := _store()
	s.record_ending("dino", "rex")
	s.record_ending("dino", "rex")
	assert_eq(s.endings_for("dino"), ["rex"])
	assert_true(s.add_seed("dino"))
	assert_false(s.add_seed("dino"), "una semilla por cuento")
	assert_eq(s.seed_count(), 1)
	s.set_resume("dino", {"page": "a3", "history": ["p1", "p2"], "flags": []})
	var again := _store()
	assert_eq(again.resume_for("dino")["page"], "a3")
	assert_eq(again.resume_for("granja"), {})


func test_store_settings() -> void:
	var s := _store()
	s.set_setting("speed", 0.8)
	assert_eq(_store().setting("speed"), 0.8)
	s.set_age(4)
	assert_eq(_store().data["age"], 4)


func test_clear_progress_keeps_settings_and_age() -> void:
	var s := _store()
	s.set_age(9)
	s.set_setting("calm", true)
	s.record_ending("dino", "rex")
	s.add_seed("dino")
	s.set_resume("dino", {"page": "a3", "history": [], "flags": []})
	s.clear_progress()
	var again := _store()
	assert_eq(again.data["age"], 9)
	assert_eq(again.setting("calm"), true)
	assert_eq(again.endings_for("dino"), [])
	assert_eq(again.seed_count(), 0)
	assert_eq(again.resume_for("dino"), {})


func test_level_follows_age_unless_set() -> void:
	var s := _store()
	s.set_age(4)
	assert_eq(s.level(), &"simple")
	s.set_setting("level", "aventura")
	assert_eq(s.level(), &"aventura")


func test_resume_to_missing_page_is_rejected() -> void:
	var st := StoryState.new(StoryData.load_from("res://test/fixtures/stories/mini"))
	assert_false(st.from_dict({"page": "pagina_borrada", "history": [], "flags": []}))


func test_locale_defaults_to_spanish() -> void:
	var s := _store()
	s.apply_locale()
	assert_eq(TranslationServer.get_locale().substr(0, 2), "es")
	assert_eq(tr("BTN_NEXT"), "Siguiente")
	s.set_setting("locale", "en")
	assert_eq(tr("BTN_NEXT"), "Next")
	s.set_setting("locale", "es")
