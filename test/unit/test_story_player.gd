extends GutTest

const MINI := "res://test/fixtures/stories/mini"
const PlayerScene := preload("res://src/ui/StoryPlayer.tscn")
const SAVE := "user://test_player_save.json"

var player: StoryPlayer
var _orig_path: String


func before_each() -> void:
	_orig_path = Store.save_path
	Store.save_path = SAVE
	Store.data = SaveData.defaults()
	player = PlayerScene.instantiate()
	player.turn_time = 0.05
	player.narration_delay = 0.05
	add_child_autofree(player)
	player.open(MINI)


func after_each() -> void:
	Audio.resume_all()
	Store.save_path = _orig_path
	Store.load_now()
	if FileAccess.file_exists(SAVE):
		DirAccess.remove_absolute(SAVE)


func _settle() -> void:
	await wait_seconds(0.15)


func test_defaults_match_spec() -> void:
	var fresh: StoryPlayer = autofree(PlayerScene.instantiate())
	assert_almost_eq(fresh.turn_time, 0.4, 0.001)
	assert_almost_eq(fresh.narration_delay, 0.3, 0.001)


func test_opens_on_first_page_and_narrates_by_itself() -> void:
	assert_eq(player.state.current, "p1")
	await _settle()
	assert_true(player.narrator.is_running(), "el relato arranca solo")


func test_double_next_during_transition_moves_once() -> void:
	await _settle()
	watch_signals(player)
	player.next()
	assert_true(player.is_transitioning())
	player.next()
	player.choose(0)
	await _settle()
	assert_signal_emit_count(player, "page_shown", 1)
	assert_eq(player.state.current, "p2")


func test_indicator_text() -> void:
	await _settle()
	assert_eq(player.controls.indicator_text(), tr("PAGE_OF") % [1, 5])
	player.next()
	await _settle()
	assert_eq(player.controls.indicator_text(), tr("PAGE_OF") % [2, 5])


func test_next_disabled_on_decision() -> void:
	await _settle()
	player.next()
	await _settle()
	assert_true(player.controls.next_button.disabled)


func test_back_returns_and_first_page_back_exits() -> void:
	await _settle()
	watch_signals(player)
	player.next()
	await _settle()
	assert_true(player.handle_back())
	await _settle()
	assert_eq(player.state.current, "p1")
	assert_true(player.handle_back())
	assert_signal_emitted(player, "exit_requested")


func test_calm_mode_uses_fade() -> void:
	Store.data["settings"]["calm"] = true
	await _settle()
	player.next()
	assert_eq(player.last_transition, &"fade")
	Store.data["settings"]["calm"] = false
	await _settle()
	player.handle_back()
	assert_eq(player.last_transition, &"turn")


func test_buttons_are_big_enough() -> void:
	# 64 dp en un celular de ~420 dpi con 1080 px de alto ≈ 96 px de la base.
	for b in player.controls.all_buttons():
		assert_true(b.custom_minimum_size.x >= 96 and b.custom_minimum_size.y >= 96, b.name)


func test_progress_saved_on_each_page() -> void:
	await _settle()
	player.next()
	await _settle()
	assert_eq(Store.resume_for("mini")["page"], "p2")


func test_resume_opens_saved_page() -> void:
	var p2: StoryPlayer = PlayerScene.instantiate()
	p2.turn_time = 0.05
	add_child_autofree(p2)
	p2.open(MINI, {"page": "p2", "history": ["p1"], "flags": []})
	assert_eq(p2.state.current, "p2")


func test_bad_resume_starts_over() -> void:
	var p2: StoryPlayer = PlayerScene.instantiate()
	add_child_autofree(p2)
	p2.open(MINI, {"page": "borrada", "history": [], "flags": []})
	assert_eq(p2.state.current, "p1")


func test_subtitles_toggle() -> void:
	Store.data["settings"]["subtitles"] = false
	player.refresh_settings()
	assert_false(player.text_panel.visible)
	Store.data["settings"]["subtitles"] = true
	player.refresh_settings()
	assert_true(player.text_panel.visible)


func test_karaoke_highlights_current_word() -> void:
	await _settle()
	player.narrator.advance(0.3)
	assert_string_contains(player.text_label.text, "[color=")
