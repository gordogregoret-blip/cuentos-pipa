extends GutTest
## Decisiones, finales, final secreto y cierre con semilla (mini fixture).

const MINI := "res://test/fixtures/stories/mini"
const PREVIEW := "res://test/fixtures/stories/preview"
const PlayerScene := preload("res://src/ui/StoryPlayer.tscn")

var p: StoryPlayer


func before_each() -> void:
	Store.save_path = "user://test_flow.json"
	Store.data = SaveData.defaults()
	p = PlayerScene.instantiate()
	p.turn_time = 0.03
	p.narration_delay = 0.01
	add_child_autofree(p)


func _read_page() -> void:
	await wait_until(func() -> bool: return not p.is_transitioning() and p.narrator.is_running(), 3.0)
	for i in 80:
		if not p.narrator.is_running():
			break
		p.narrator.advance(0.2)


func _goto(id: String) -> void:
	p.state.current = id
	p._show_page(&"forward")
	await _read_page()


func test_cards_only_after_narration() -> void:
	p.open(MINI, {"page": "p2", "history": ["p1"], "flags": []})
	await wait_until(func() -> bool: return p.narrator.is_running(), 3.0)
	assert_false(p.decision_cards.visible, "esperan a que termine el relato")
	for i in 80:
		p.narrator.advance(0.2)
	assert_true(p.decision_cards.visible)
	assert_eq(p.decision_cards.cards.size(), 2)


func test_card_tap_chooses() -> void:
	p.open(MINI, {"page": "p2", "history": ["p1"], "flags": []})
	await _read_page()
	p.decision_cards.cards[1].pressed.emit()
	assert_eq(p.state.current, "b5")
	assert_false(p.decision_cards.visible)


func test_ending_is_recorded() -> void:
	p.open(MINI)
	await _goto("a6")
	assert_eq(Store.endings_for("mini"), ["rio"])


func test_secret_route() -> void:
	p.open(MINI, {"page": "a5", "history": ["p1", "p2"], "flags": ["huella_1", "huella_2"]})
	await _read_page()
	p.next()
	await _read_page()
	assert_eq(p.state.current, "s6")
	assert_eq(Store.endings_for("mini"), ["secreto"])


func test_closing_plants_seed_and_offers_buttons() -> void:
	p.open(MINI, {"page": "a6", "history": ["p1", "p2", "a5"], "flags": ["huella_1"]})
	await _read_page()
	p.next()
	await _read_page()
	assert_eq(p.state.current, "p7")
	assert_eq(Store.seed_count(), 1)
	assert_eq(Store.resume_for("mini"), {}, "el cuento terminado no se retoma")
	assert_true(p.closing.visible)
	assert_eq(p.closing.message_label.text, "Probar es divertido.")
	assert_eq(p.closing.emotion_buttons.size(), 6)
	assert_eq(p.closing.action_buttons.size(), 3)


func test_closing_read_again() -> void:
	p.open(MINI, {"page": "p7", "history": ["p1", "p2", "a5", "a6"], "flags": ["huella_1"]})
	await _read_page()
	p.closing.read_again.emit()
	await wait_until(func() -> bool: return not p.is_transitioning(), 2.0)
	assert_eq(p.state.current, "p1")
	assert_eq(p.state.flags.size(), 0)
	assert_false(p.closing.visible)


func test_closing_other_path() -> void:
	p.open(MINI, {"page": "p7", "history": ["p1", "p2", "a5", "a6"], "flags": []})
	await _read_page()
	p.closing.other_path.emit()
	await wait_until(func() -> bool: return not p.is_transitioning(), 2.0)
	assert_eq(p.state.current, "p2")


func test_closing_plaza() -> void:
	p.open(MINI, {"page": "p7", "history": ["p1", "p2", "a5", "a6"], "flags": []})
	await _read_page()
	watch_signals(p)
	p.closing.to_plaza.emit()
	assert_signal_emitted(p, "exit_requested")


func test_emotion_choice_is_optional_and_answers() -> void:
	p.open(MINI, {"page": "p7", "history": ["p1", "p2", "a5", "a6"], "flags": []})
	await _read_page()
	p.closing.choose_emotion("verde")
	assert_eq(p.closing.chosen_emotion, "verde")
	assert_string_contains(p.closing.answer_label.text, tr("EMO_verde"))


func test_preview_end_shows_to_be_continued() -> void:
	p.open(PREVIEW)
	await _read_page()
	assert_true(p.closing.visible)
	assert_true(p.closing.is_preview)
	assert_eq(p.closing.action_buttons.size(), 1, "solo Volver a la plaza")
	assert_eq(Store.seed_count(), 0, "un cuento de prueba no da semilla")


func test_back_closes_closing_overlay_first() -> void:
	p.open(MINI, {"page": "p2", "history": ["p1"], "flags": []})
	await _read_page()
	assert_true(p.handle_back())
	await wait_until(func() -> bool: return not p.is_transitioning(), 2.0)
	assert_eq(p.state.current, "p1", "con las tarjetas abiertas, Atrás vuelve una página")


func test_text_panel_hidden_behind_closing() -> void:
	p.open(MINI, {"page": "p7", "history": ["p1", "p2", "a5", "a6"], "flags": []})
	await _read_page()
	assert_false(p.text_panel.visible)
