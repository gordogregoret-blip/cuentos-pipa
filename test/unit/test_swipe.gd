extends GutTest


func _swipe(from: Vector2, to: Vector2) -> StringName:
	var s := SwipeDetector.new()
	s.begin(from)
	return s.end(to)


func test_short_swipe_ignored() -> void:
	assert_eq(_swipe(Vector2(500, 500), Vector2(381, 500)), &"")


func test_left_swipe_is_next() -> void:
	assert_eq(_swipe(Vector2(500, 500), Vector2(380, 500)), &"next")


func test_right_swipe_is_back() -> void:
	assert_eq(_swipe(Vector2(500, 500), Vector2(700, 520)), &"back")


func test_mostly_vertical_ignored() -> void:
	assert_eq(_swipe(Vector2(500, 500), Vector2(370, 700)), &"")


func test_end_without_begin() -> void:
	assert_eq(SwipeDetector.new().end(Vector2(0, 0)), &"")
