extends GutTest

var panel: AdultPanel


func before_each() -> void:
	Store.save_path = "user://test_adult.json"
	Store.data = SaveData.defaults()
	Store.data["age"] = 7
	panel = AdultPanel.new()
	panel.index = StoryIndex.load_from("res://test/fixtures/stories/index.json")
	add_child_autofree(panel)


func after_each() -> void:
	Audio.apply_settings()


func test_volume_saves_and_applies() -> void:
	panel.set_volume("vol_voz", 0.3)
	assert_eq(Store.setting("vol_voz"), 0.3)
	assert_almost_eq(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(&"Voz")), linear_to_db(0.3), 0.01)


func test_speed_options() -> void:
	assert_eq(AdultPanel.SPEEDS, [0.8, 1.0, 1.2])
	panel.set_speed(1.2)
	assert_eq(Store.setting("speed"), 1.2)
	assert_almost_eq(Audio.speed, 1.2, 0.001)


func test_toggles_save() -> void:
	for key in ["calm", "subtitles", "lock_taps", "easy_font"]:
		var before: bool = Store.setting(key)
		panel.set_toggle(key, not before)
		assert_eq(Store.setting(key), not before, key)


func test_level_and_age() -> void:
	panel.set_level("aventura")
	assert_eq(Store.level(), &"aventura")
	panel.set_age(4)
	assert_eq(Store.data["age"], 4)


func test_turn_mode() -> void:
	panel.set_turn_mode("swipe")
	assert_eq(Store.setting("turn_mode"), "swipe")


func test_endings_listed_per_story() -> void:
	Store.record_ending("mini", "rio")
	panel.rebuild()
	assert_string_contains(panel.endings_text(), "Cuento mínimo: 1 / 3")


func test_erase_needs_confirmation() -> void:
	Store.record_ending("mini", "rio")
	panel.request_erase()
	assert_true(panel.erase_confirm.visible)
	assert_eq(Store.endings_for("mini"), ["rio"], "todavía no borró")
	panel.confirm_erase()
	assert_eq(Store.endings_for("mini"), [])
	assert_eq(Store.data["age"], 7)


func test_links_only_here() -> void:
	assert_true(Links.PRIVACY.begins_with("https://"))
	assert_eq(panel.link_buttons.size(), 3)
