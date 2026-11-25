extends GutTest
## Botón Atrás de Android: nunca cierra la app de golpe.

const MainScene := preload("res://src/Main.tscn")

var main: Main


func before_each() -> void:
	Store.save_path = "user://test_back.json"
	Store.data = SaveData.defaults()


func _main(age: int) -> Main:
	Store.data["age"] = age
	main = MainScene.instantiate()
	main.index_path = "res://test/fixtures/stories/index.json"
	main.quit_on_confirm = false
	add_child_autofree(main)
	return main


func test_first_run_without_age() -> void:
	_main(0)
	assert_true(main.current is FirstRun)


func test_library_with_age() -> void:
	_main(7)
	assert_true(main.current is Library)


func test_back_on_plaza_asks_to_confirm() -> void:
	_main(7)
	main.handle_back()
	assert_true(main.top_overlay() is ConfirmExit)
	main.handle_back()
	assert_null(main.top_overlay(), "Atrás de nuevo cierra la pregunta")


func test_back_closes_overlay_before_page() -> void:
	_main(7)
	main.open_story("mini", {"page": "p2", "history": ["p1"], "flags": []})
	var player: StoryPlayer = main.current
	player.turn_time = 0.02
	await wait_until(func() -> bool: return not player.is_transitioning(), 2.0)
	var dummy := Control.new()
	main.open_overlay(dummy)
	main.handle_back()
	assert_null(main.top_overlay())
	assert_eq(player.state.current, "p2", "la página no cambió")
	main.handle_back()
	await wait_until(func() -> bool: return not player.is_transitioning(), 2.0)
	assert_eq(player.state.current, "p1")


func test_exit_story_returns_to_plaza() -> void:
	_main(7)
	main.open_story("mini")
	(main.current as StoryPlayer).exit_requested.emit()
	assert_true(main.current is Library)


func test_choosing_door_opens_cover_then_story() -> void:
	_main(7)
	(main.current as Library).story_chosen.emit("mini")
	var cover := main.top_overlay() as Cover
	assert_not_null(cover)
	cover.start.emit()
	assert_true(main.current is StoryPlayer)
	assert_null(main.top_overlay())
