extends GutTest

const MINI := "res://test/fixtures/stories/mini"

var data: StoryData


func before_each() -> void:
	data = StoryData.load_from(MINI)


func after_each() -> void:
	Audio.stop_all()


func _tap(index: int, page := "p1") -> Tappable:
	var t := Tappable.new()
	t.setup(data.page(page)["tappables"][index], data, page)
	add_child_autofree(t)
	return t


func test_tap_emits_and_plays() -> void:
	var t := _tap(1)
	watch_signals(t)
	assert_true(t.tap())
	assert_signal_emitted(t, "tapped")
	assert_eq(get_signal_parameters(t, "tapped")[0]["flag"], "huella_1")
	assert_almost_eq(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(&"Voz")), -8.0, 0.01)


func test_locked_does_nothing() -> void:
	var t := _tap(0)
	watch_signals(t)
	t.locked = true
	assert_false(t.tap())
	assert_signal_not_emitted(t, "tapped")


func test_min_touch_size() -> void:
	var t := _tap(0)
	assert_true(t.custom_minimum_size.x >= 96 and t.custom_minimum_size.y >= 96)


func test_place_in_page() -> void:
	var t := _tap(1)
	t.place_in(Vector2(1920, 1080))
	assert_eq(t.position + t.size / 2.0, Vector2(0.5 * 1920, 0.7 * 1080))


func test_cast_art_uses_rig() -> void:
	var t := _tap(2)
	assert_not_null(t.rig, "cast:fido arma a Fido")


func test_hint_glow() -> void:
	var t := _tap(0)
	t.show_hint(true)
	assert_true(t.hint_visible())
	t.show_hint(false)
	assert_false(t.hint_visible())


func test_word_vo_path() -> void:
	var t := _tap(0)
	assert_eq(t.word_vo, MINI + "/vo/p1_tap_sol.ogg")
