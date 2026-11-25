extends GutTest

const MINI := "res://test/fixtures/stories/mini"
const PlayerScene := preload("res://src/ui/StoryPlayer.tscn")


func test_fires_at_six_seconds_not_before() -> void:
	var h := HintTimer.new(6.0)
	assert_false(h.tick(5.9))
	assert_true(h.tick(0.1))
	assert_false(h.tick(10.0), "dispara una sola vez hasta que se toque algo")


func test_touch_resets() -> void:
	var h := HintTimer.new(6.0)
	h.tick(5.0)
	h.touch()
	assert_false(h.tick(5.0))
	assert_true(h.tick(1.0))


func _player() -> StoryPlayer:
	Store.data = SaveData.defaults()
	Store.save_path = "user://test_hint.json"
	var p: StoryPlayer = PlayerScene.instantiate()
	p.turn_time = 0.05
	p.narration_delay = 0.01
	add_child_autofree(p)
	p.open(MINI)
	return p


func _finish_narration(p: StoryPlayer) -> void:
	await wait_until(func() -> bool: return p.narrator.is_running(), 3.0)
	for i in 60:
		p.narrator.advance(0.2)


func test_lumi_appears_after_idle() -> void:
	var p := _player()
	await _finish_narration(p)
	p.tick_hint(6.0)
	var shown := p.page_view.tappables.filter(func(t: Tappable) -> bool: return t.hint_visible())
	assert_eq(shown.size(), 1)


func test_no_hint_while_paused() -> void:
	var p := _player()
	await _finish_narration(p)
	Audio.pause_all()
	p.tick_hint(10.0)
	Audio.resume_all()
	var shown := p.page_view.tappables.filter(func(t: Tappable) -> bool: return t.hint_visible())
	assert_eq(shown.size(), 0)


func test_hint_prefers_untouched() -> void:
	var p := _player()
	await _finish_narration(p)
	p.page_view.tappables[0].tap()
	p.tick_hint(6.0)
	assert_true(p.page_view.tappables[1].hint_visible())


func test_lock_until_narration_ends() -> void:
	Store.data = SaveData.defaults()
	Store.data["settings"]["lock_taps"] = true
	var p: StoryPlayer = PlayerScene.instantiate()
	p.turn_time = 0.05
	p.narration_delay = 0.01
	add_child_autofree(p)
	p.open(MINI)
	assert_true(p.page_view.tappables[0].locked)
	await _finish_narration(p)
	assert_false(p.page_view.tappables[0].locked)
	Store.data["settings"]["lock_taps"] = false


func test_flag_from_tap_is_kept() -> void:
	var p := _player()
	await wait_seconds(0.1)
	p.page_view.tappables[1].tap()
	assert_true("huella_1" in p.state.flags)


func test_pendant_follows_page() -> void:
	var p := _player()
	await _finish_narration(p)
	assert_eq(p.pendant_color, "amarillo")
