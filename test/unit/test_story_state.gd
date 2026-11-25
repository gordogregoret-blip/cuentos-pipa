extends GutTest

const MINI := "res://test/fixtures/stories/mini"

var data: StoryData
var st: StoryState


func before_each() -> void:
	data = StoryData.load_from(MINI)
	st = StoryState.new(data)
	st.start()


func test_load_reads_story() -> void:
	assert_not_null(data)
	assert_eq(data.id, "mini")
	assert_eq(data.title, "Cuento mínimo")
	assert_eq(data.message, "Probar es divertido.")


func test_load_missing_returns_null() -> void:
	assert_null(StoryData.load_from("res://no/existe"))


func test_text_and_paths_by_level() -> void:
	assert_eq(data.text("p1", &"simple"), "Pipa está en la plaza.")
	assert_eq(data.vo_path("p1", &"cuento"), MINI + "/vo/p1_cuento.ogg")
	assert_eq(data.timings_path("p1", &"aventura"), MINI + "/vo/p1_aventura.json")
	assert_eq(data.asset("art/fondo.svg"), MINI + "/art/fondo.svg")


func test_start_on_first_page() -> void:
	assert_eq(st.current, "p1")
	assert_eq(st.step(), 1)
	assert_eq(st.kind(), &"next")


func test_next_and_decision() -> void:
	assert_true(st.go_next())
	assert_eq(st.current, "p2")
	assert_eq(st.kind(), &"decision")
	assert_false(st.go_next(), "una decisión no avanza con Siguiente")
	assert_true(st.choose(1))
	assert_eq(st.current, "b5")
	assert_eq(st.step(), 3)


func test_choose_outside_decision_fails() -> void:
	assert_false(st.choose(0))
	assert_eq(st.current, "p1")


func test_back() -> void:
	assert_false(st.back(), "en la primera página no hay atrás")
	st.go_next()
	st.choose(0)
	assert_true(st.back())
	assert_eq(st.current, "p2")
	assert_eq(st.history, [] as Array[String] + ["p1"])


func test_secret_route_with_all_flags() -> void:
	st.set_flag("huella_1")
	st.go_next()
	st.choose(0)
	st.set_flag("huella_2")
	st.go_next()
	assert_eq(st.current, "s6")


func test_regular_route_without_all_flags() -> void:
	st.set_flag("huella_1")
	st.go_next()
	st.choose(0)
	st.go_next()
	assert_eq(st.current, "a6")


func test_flags_are_unique() -> void:
	st.set_flag("huella_1")
	st.set_flag("huella_1")
	assert_eq(st.flags.size(), 1)


func test_closing_kind_and_ending() -> void:
	st.go_next()
	st.choose(0)
	st.go_next()
	assert_eq(st.ending(), {"id": "rio", "title": "El río que canta"})
	st.go_next()
	assert_eq(st.kind(), &"closing")
	assert_false(st.go_next())


func test_rewind_to_last_decision() -> void:
	st.go_next()
	st.choose(0)
	st.go_next()
	st.go_next()
	assert_true(st.rewind_to_last_decision())
	assert_eq(st.current, "p2")
	assert_eq(st.step(), 2)


func test_restart_clears_flags() -> void:
	st.set_flag("huella_1")
	st.go_next()
	st.start()
	assert_eq(st.current, "p1")
	assert_eq(st.flags.size(), 0)


func test_roundtrip_dict() -> void:
	st.set_flag("huella_1")
	st.go_next()
	var other := StoryState.new(data)
	assert_true(other.from_dict(st.to_dict()))
	assert_eq(other.current, "p2")
	assert_eq(other.history, st.history)
	assert_eq(other.flags, st.flags)


func test_from_dict_rejects_missing_page() -> void:
	var other := StoryState.new(data)
	assert_false(other.from_dict({"page": "zz", "history": [], "flags": []}))
	assert_false(other.from_dict({"page": "p2", "history": ["zz"], "flags": []}))
	assert_false(other.from_dict({}))
