extends GutTest
## "El huevo que brillaba": 4 finales + secreto, 7 páginas por recorrido.

const DINO := "res://stories/dino"

var data: StoryData


func before_each() -> void:
	data = StoryData.load_from(DINO)


func _walk(choices: Array, flags: Array = []) -> StoryState:
	var st := StoryState.new(data)
	st.start()
	var c := 0
	var guard := 0
	while st.kind() != &"closing" and guard < 20:
		guard += 1
		for f in flags:
			if _page_sets(st.current, f):
				st.set_flag(f)
		if st.kind() == &"decision":
			st.choose(choices[c])
			c += 1
		else:
			st.go_next()
	return st


func _page_sets(pid: String, flag: String) -> bool:
	for t in data.page(pid)["tappables"]:
		if t.get("flag", "") == flag:
			return true
	return false


func _ending_of(st: StoryState) -> String:
	return data.page(st.history[-1]).get("ending", {}).get("id", "")


func test_four_endings_in_seven_pages() -> void:
	var expected := {[0, 0]: "paso_a_paso", [0, 1]: "pedir_ayuda", [1, 0]: "rex_gigante_bueno", [1, 1]: "amigo_nuevo"}
	for choices in expected:
		var st := _walk(choices)
		assert_eq(st.step(), 7, "camino %s" % [choices])
		assert_eq(_ending_of(st), expected[choices])


func test_secret_with_three_golden_prints() -> void:
	for choices in [[0, 0], [1, 1]]:
		var st := _walk(choices, ["huella_1", "huella_2", "huella_3"])
		assert_eq(_ending_of(st), "secreto_volar")
		assert_eq(st.step(), 7)


func test_two_prints_are_not_enough() -> void:
	var st := _walk([0, 1], ["huella_1", "huella_3"])
	assert_eq(_ending_of(st), "pedir_ayuda")


func test_message_and_endings() -> void:
	assert_eq(data.message, "Lo distinto no da miedo cuando lo conocés.")
	assert_eq(data.ending_ids().size(), 5)
	assert_eq(data.path_length(), 7)


func test_every_pendant_change_is_named_in_text() -> void:
	for pid in data.pages:
		for e in data.page(pid).get("pendant", []):
			for level in Levels.ALL:
				assert_string_contains(data.text(pid, level), "El colgante está %s" % e["color"], "%s/%s" % [pid, level])


func test_index_has_two_open_and_six_locked() -> void:
	var idx := StoryIndex.load_from()
	assert_eq(idx.entries.size(), 8)
	assert_eq(idx.playable().map(func(e: Dictionary) -> String: return e["id"]), ["dino", "granja"])
