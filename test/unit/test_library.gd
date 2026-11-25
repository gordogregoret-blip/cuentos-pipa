extends GutTest

const INDEX := "res://test/fixtures/stories/index.json"

var lib: Library


func before_each() -> void:
	Store.save_path = "user://test_library.json"
	Store.data = SaveData.defaults()
	Store.data["age"] = 6
	lib = Library.new()
	add_child_autofree(lib)
	lib.build(StoryIndex.load_from(INDEX))


func test_index_loads_entries() -> void:
	var idx := StoryIndex.load_from(INDEX)
	assert_eq(idx.entries.size(), 8)
	assert_eq(idx.playable().size(), 2)
	assert_eq(idx.dir_for("mini"), "res://test/fixtures/stories/mini")


func test_missing_index_is_empty() -> void:
	assert_eq(StoryIndex.load_from("res://nada.json").entries.size(), 0)


func test_eight_doors_six_locked() -> void:
	assert_eq(lib.doors.size(), 8)
	var locked := lib.doors.filter(func(d: Door) -> bool: return d.locked)
	assert_eq(locked.size(), 6)
	assert_eq(locked[0].sign_label.text, tr("COMING_SOON"))


func test_stars_show_found_endings() -> void:
	Store.record_ending("mini", "rio")
	lib.refresh()
	var d: Door = lib.doors[0]
	assert_eq(d.stars_found, 1)
	assert_eq(d.stars_total, 3)


func test_locked_door_does_not_open() -> void:
	watch_signals(lib)
	lib.doors[2].press()
	assert_signal_not_emitted(lib, "story_chosen")


func test_open_door_emits_story() -> void:
	watch_signals(lib)
	lib.doors[0].press()
	assert_signal_emitted_with_parameters(lib, "story_chosen", ["mini"])


func test_seeds_on_tree() -> void:
	Store.add_seed("mini")
	lib.refresh()
	assert_eq(lib.tree.seeds_shown, 1)
	assert_false(lib.tree.bloomed)


func test_tree_blooms_with_seven_seeds() -> void:
	for i in 7:
		Store.add_seed("s%d" % i)
	lib.refresh()
	assert_true(lib.tree.bloomed)


func test_cover_offers_continue_only_with_resume() -> void:
	var c := Cover.new()
	add_child_autofree(c)
	c.setup(StoryData.load_from("res://test/fixtures/stories/mini"), {})
	assert_false(c.continue_button.visible)
	c.setup(StoryData.load_from("res://test/fixtures/stories/mini"), {"page": "p2", "history": ["p1"], "flags": []})
	assert_true(c.continue_button.visible)


func test_first_run_suggests_level() -> void:
	var f := FirstRun.new()
	add_child_autofree(f)
	watch_signals(f)
	f.pick_age(4)
	assert_string_contains(f.level_label.text, tr("LEVEL_simple"))
	f.pick_age(10)
	assert_string_contains(f.level_label.text, tr("LEVEL_aventura"))
	f.confirm()
	assert_eq(Store.data["age"], 10)
	assert_eq(Store.level(), &"aventura")
	assert_signal_emitted(f, "done")


func test_first_run_needs_age_first() -> void:
	var f := FirstRun.new()
	add_child_autofree(f)
	assert_true(f.start_button.disabled)
