extends GutTest

const MINI := "res://test/fixtures/stories/mini"


func test_phases_four_and_four() -> void:
	assert_eq(BreathCycle.phase_at(0.0), &"in")
	assert_eq(BreathCycle.phase_at(3.99), &"in")
	assert_eq(BreathCycle.phase_at(4.0), &"out")
	assert_eq(BreathCycle.phase_at(7.99), &"out")
	assert_eq(BreathCycle.phase_at(8.0), &"in")


func test_scale_inflates_and_deflates() -> void:
	assert_almost_eq(BreathCycle.scale_at(0.0), 1.0, 0.001)
	assert_almost_eq(BreathCycle.scale_at(4.0), 1.4, 0.001)
	assert_almost_eq(BreathCycle.scale_at(8.0), 1.0, 0.001)
	assert_true(BreathCycle.scale_at(2.0) > 1.0 and BreathCycle.scale_at(2.0) < 1.4)


func test_calm_corner_guides_and_returns() -> void:
	var c := CalmCorner.new()
	add_child_autofree(c)
	watch_signals(c)
	c.advance(0.1)
	assert_eq(c.guide_label.text, tr("CALM_IN"))
	c.advance(4.0)
	assert_eq(c.guide_label.text, tr("CALM_OUT"))
	assert_almost_eq(c.lumi.scale.x, BreathCycle.scale_at(4.1), 0.01)
	c.back_button.pressed.emit()
	assert_signal_emitted(c, "close_requested")


func test_calm_holds_story_and_restarts_narration() -> void:
	Store.data = SaveData.defaults()
	Store.save_path = "user://test_calm.json"
	var main: Main = preload("res://src/Main.tscn").instantiate()
	main.index_path = "res://test/fixtures/stories/index.json"
	Store.data["age"] = 6
	add_child_autofree(main)
	main.open_story("mini")
	var p: StoryPlayer = main.current
	await wait_until(func() -> bool: return p.narrator.is_running(), 3.0)
	main.open_calm()
	assert_true(main.top_overlay() is CalmCorner)
	assert_false(p.narrator.is_running(), "el relato se detiene")
	p.tick_hint(30.0)
	assert_eq(p.page_view.tappables.filter(func(t: Tappable) -> bool: return t.hint_visible()).size(), 0)
	main.handle_back()
	assert_null(main.top_overlay())
	await wait_until(func() -> bool: return p.narrator.is_running(), 3.0)
	assert_true(p.narrator.is_running(), "vuelve a leer la página")
